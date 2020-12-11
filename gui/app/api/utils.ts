import fs, { FSWatcher } from 'fs';
import path from 'path';
import os from 'os';
import checkInternetConnection from 'check-internet-connected';
// import type { FileFilter } from '../types/common';
// import type { AnalysisFileTypes } from '../types/analysis';
import TimeoutError from '../errors/TimeoutError';
import type { JobPath } from '../interfaces';

let watcher: FSWatcher | null = null;

export default {
  cpuCount() {
    return os.cpus().length;
  },
  // supportedAnalysisFileTypes() {
  //   return {
  //     fastq: 'FASTQ',
  //     bam: 'BAM',
  //     sam: 'SAM',
  //   };
  // },
  // analysisFileExtensions(type: AnalysisFileTypes): FileFilter[] {
  //   switch (type) {
  //     case 'fastq':
  //       return [{ name: 'FASTQ files', extensions: ['fq', 'fastq', 'gz'] }];
  //     case 'bam':
  //       return [{ name: 'BAM files', extensions: ['bam'] }];
  //     case 'sam':
  //       return [{ name: 'SAM files', extensions: ['sam'] }];
  //     default:
  //       return [];
  //   }
  // },
  filterByKey<T>(raw: T, callback: (k: keyof T) => boolean): Partial<T> {
    return Object.keys(raw)
      .filter((k) => callback(k as keyof T))
      .reduce((obj, key) => {
        return {
          ...obj,
          [key]: raw[key as keyof T],
        };
      }, {});
  },
  toArray(list: never) {
    return Array.prototype.slice.call(list || [], 0);
  },
  async retryFunction<T>(
    f: (idx: number) => Promise<T>,
    timeout = 0,
    maxTries = 3
  ): Promise<T> {
    const realMaxTries = Math.max(1, maxTries);
    // eslint-disable-next-line no-plusplus
    for (let t = 0; t < realMaxTries; t++) {
      try {
        // eslint-disable-next-line no-await-in-loop
        return await this.promiseTimeout(f(t), timeout);
      } catch (e) {
        if (!(e instanceof TimeoutError)) {
          throw e;
        }
      }
    }
    throw new TimeoutError(
      'Operation timed out too many times. No other attempt will be made.'
    );
  },
  async promiseTimeout<T>(p: Promise<T>, timeout = 0): Promise<T> {
    if (timeout === 0) return p;
    return Promise.race([
      p,
      // eslint-disable-next-line promise/param-names
      new Promise((_resolve, reject) => {
        setTimeout(
          () => reject(new TimeoutError('Operation timed out')),
          timeout
        );
      }) as Promise<never>,
    ]);
  },
  async waitExists(filePath: string, timeout = 0): Promise<never> {
    return new Promise((resolve, reject) => {
      let timer: number | null = null;
      const closeWatcher = () => {
        if (watcher !== null) {
          watcher.close();
          watcher = null;
        }
      };
      const closeTimeout = () => {
        if (timer !== null) {
          clearTimeout(timer);
        }
      };
      if (timeout > 0) {
        timer = setTimeout(() => {
          closeWatcher();
          reject(
            new TimeoutError(`Unable to find ${filePath}. Operation timed out`)
          );
        }, timeout);
      }

      fs.access(filePath, fs.constants.R_OK, (err) => {
        if (!err) {
          closeTimeout();
          closeWatcher();
          resolve();
        }
      });

      const dir = path.dirname(filePath);
      const basename = path.basename(filePath);
      watcher = fs.watch(dir, (eventType, filename) => {
        if (eventType === 'rename' && filename === basename) {
          closeTimeout();
          closeWatcher();
          resolve();
        }
      });
    });
  },
  dashToWordString(s: string) {
    return s.replace(/[_\\-]([a-z0-9])/g, (g) => ` ${g[1].toUpperCase()}`);
  },
  capitalize(s: string) {
    return s.charAt(0).toUpperCase() + s.slice(1);
  },
  async isOnline(): Promise<boolean> {
    try {
      await checkInternetConnection({
        timeout: 5000,
        retries: 3,
        domain: 'https://alpha.dmi.unict.it',
      });
      return true;
    } catch (_) {
      return false;
    }
  },
  // eslint-disable-next-line @typescript-eslint/ban-types
  hasProperty<X extends {}, Y extends PropertyKey, Z>(
    obj: X,
    prop: Y
  ): obj is X & Record<Y, Z> {
    return Object.prototype.hasOwnProperty.call(obj, prop);
  },
  // eslint-disable-next-line @typescript-eslint/ban-types
  hasPathProperty<X extends {}, Y extends PropertyKey>(
    obj: X,
    prop: Y
  ): obj is X & Record<Y, JobPath> {
    return (
      this.hasProperty(obj, prop) &&
      this.hasProperty(obj[prop], 'path') &&
      this.hasProperty(obj[prop], 'url')
    );
  },
};
