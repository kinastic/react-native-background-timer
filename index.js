import {
  NativeModules,
  NativeEventEmitter
} from 'react-native';
import moment from 'moment';

const { RNBackgroundTimer } = NativeModules;
const Emitter = new NativeEventEmitter(RNBackgroundTimer);

class BackgroundTimer {

  constructor() {
    this.uniqueId = 0;
    this.callbacks = {};
    Emitter.addListener('backgroundTimer.timeout', (id) => {
      if (__DEV__) {
        console.log(`Got timeout for ${id} at ${moment().format('YYYY-MM-DD HH:mm:ss')}`);
      }
      if (this.callbacks[id]) {
        const callback = this.callbacks[id].callback;
        if (!this.callbacks[id].interval) {
          delete this.callbacks[id];
        }
        else {
          RNBackgroundTimer.setTimeout(id, this.callbacks[id].timeout);
        }
        callback();
      }
    });
  }

  // Original API
  start = (delay) => {
    return RNBackgroundTimer.start(delay);
  };

  stop = () => {
    return RNBackgroundTimer.stop();
  };

  // New API, allowing for multiple timers
  setTimeout = (callback, timeout) => {
    const timeoutId = ++this.uniqueId;
    this.callbacks[timeoutId] = {
      callback: callback,
      interval: false,
      timeout: timeout
    };
    RNBackgroundTimer.setTimeout(timeoutId, timeout);
    return timeoutId;
  };

  clearTimeout = (timeoutId) => {
    if (this.callbacks[timeoutId]) {
      delete this.callbacks[timeoutId];
      RNBackgroundTimer.clearTimeout(timeoutId);
    }
  };

  setInterval = (callback, timeout) => {
    const intervalId = ++this.uniqueId;
    this.callbacks[intervalId] = {
      callback: callback,
      interval: true,
      timeout: timeout
    };
    RNBackgroundTimer.setTimeout(intervalId, timeout);
    return intervalId;
  };

  clearInterval = (intervalId) => {
    if (this.callbacks[intervalId]) {
      delete this.callbacks[intervalId];
      RNBackgroundTimer.clearTimeout(intervalId);
    }
  };
};

export default new BackgroundTimer();
