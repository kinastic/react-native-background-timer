//
//  RNBackgroundTimer.m
//  react-native-background-timer
//
//  Created by IjzerenHein on 06-09-2016.
//  Copyright (c) ATO Gear. All rights reserved.
//

@import UIKit;
#import "RNBackgroundTimer.h"

#define YES_STRING @"Y"

@implementation RNBackgroundTimer {
    UIBackgroundTaskIdentifier bgTask;
    int delay;
    NSDateFormatter *formatter;
    NSMutableDictionary<NSNumber*, NSString*> *timerIds;
}

RCT_EXPORT_MODULE()

- (NSArray<NSString *> *)supportedEvents { return @[@"backgroundTimer", @"backgroundTimer.timeout"]; }

- (id) init
{
    self = [super init];
    if (nil != self) {
        timerIds = [[NSMutableDictionary alloc] init];
#ifdef DEBUG
        formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
#endif
    }
    return self;
}


- (void) _start
{
    [self _stop];
    
    bgTask = [[UIApplication sharedApplication] beginBackgroundTaskWithName:@"RNBackgroundTimer" expirationHandler:^{
        // Clean up any unfinished task business by marking where you
        // stopped or ending the task outright.
        [[UIApplication sharedApplication] endBackgroundTask:bgTask];
        bgTask = UIBackgroundTaskInvalid;
    }];

    UIBackgroundTaskIdentifier thisBgTask = bgTask;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, delay * NSEC_PER_MSEC), dispatch_get_main_queue(), ^{
        if ([self bridge] != nil && thisBgTask == bgTask) {
            [self sendEventWithName:@"backgroundTimer" body:[NSNumber numberWithInt:(int)thisBgTask]];
            [self _start];
        }
    });
}

- (void) _stop
{
    if (bgTask != UIBackgroundTaskInvalid) {
        [[UIApplication sharedApplication] endBackgroundTask:bgTask];
        bgTask = UIBackgroundTaskInvalid;
    }
}

RCT_EXPORT_METHOD(start:(int)_delay
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
    delay = _delay;
    [self _start];
    resolve([NSNumber numberWithBool:YES]);
}

RCT_EXPORT_METHOD(stop:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
    [self _stop];
    resolve([NSNumber numberWithBool:YES]);
}

RCT_EXPORT_METHOD(clearTimeout:(int)timeoutId)
{
    [timerIds removeObjectForKey:[NSNumber numberWithInt:timeoutId]];
}

RCT_EXPORT_METHOD(setTimeout:(int)timeoutId
                     timeout:(int)timeout)
{
    timerIds[[NSNumber numberWithInteger:timeoutId]] = YES_STRING;
    __block UIBackgroundTaskIdentifier task = [[UIApplication sharedApplication] beginBackgroundTaskWithName:@"RNBackgroundTimer" expirationHandler:^{
        [[UIApplication sharedApplication] endBackgroundTask:task];
    }];
    
#ifdef DEBUG
    NSLog(@"Setting timeout %d for %d at %@", timeout, timeoutId, [formatter stringFromDate:[NSDate date]]);
#endif

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, timeout * NSEC_PER_MSEC), dispatch_get_main_queue(), ^{
        if ([self bridge] != nil) {
            NSNumber *numberTimeout = [NSNumber numberWithInt:timeoutId];
            if (nil != [timerIds objectForKey:numberTimeout])
            {
                [timerIds removeObjectForKey:numberTimeout];
                [self sendEventWithName:@"backgroundTimer.timeout" body:numberTimeout];
#ifdef DEBUG
                NSLog(@"Emitted backgroundTimer for %d with timeout %d at %@", timeoutId, timeout, [formatter stringFromDate:[NSDate date]]);
#endif
            }
        } else {
            NSLog(@"Unable to callback since bridge was nil");
        }
        [[UIApplication sharedApplication] endBackgroundTask:task];
    });
}

@end
