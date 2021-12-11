import fs, { FSWatcher } from 'fs';
import path from 'path';
import { has } from 'lodash';
import checkInternetConnection from 'check-internet-connected';
// import type { FileFilter } from '../types/common';
// import type { AnalysisFileTypes } from '../types/analysis';
import { container } from 'tsyringe';
import TimeoutError from '../errors/TimeoutError';
import type { FileFilter, JobPath } from '../interfaces';
import { HttpClient } from '../apiConnector';

export type Capabilities = {
  containerVersion: string;
  containerVersionNumber: number;
  maxMemory: number;
  availableMemory: number;
  numCores: number;
  usedCores: number;
  availableCores: number;
};

let watcher: FSWatcher | null = null;

let containerCapabilities: Capabilities | undefined;

export default {
  capabilitiesLoaded() {
    return !!containerCapabilities;
  },
  capabilities() {
    return containerCapabilities;
  },
  async refreshCapabilities() {
    const httpClient = container.resolve(HttpClient);
    const response = await httpClient.get<{
      data: Capabilities;
    }>('sys-info');
    containerCapabilities = {
      ...response.data,
      availableCores: response.data.numCores - response.data.usedCores,
    };
    return containerCapabilities;
  },
  async containerVersion() {
    if (!containerCapabilities) {
      return (await this.refreshCapabilities()).containerVersion;
    }
    return containerCapabilities.containerVersion;
  },
  async maxMemory() {
    if (!containerCapabilities) {
      return (await this.refreshCapabilities()).maxMemory;
    }
    return containerCapabilities.maxMemory;
  },
  async availableCores(refresh = false) {
    if (refresh || !containerCapabilities) {
      return (await this.refreshCapabilities()).availableCores;
    }
    return containerCapabilities.availableCores;
  },
  async cpuCount(refresh = false) {
    if (refresh || !containerCapabilities) {
      return (await this.refreshCapabilities()).numCores;
    }
    return containerCapabilities.numCores;
  },
  supportedAnalysisFileTypes() {
    return {
      fastq: 'FASTQ',
      bam: 'BAM',
      ubam: 'uBAM',
      vcf: 'VCF',
    };
  },
  analysisFileExtensions(type: string): FileFilter[] {
    switch (type) {
      case 'fastq':
        return [{ name: 'FASTQ files', extensions: ['fq', 'fastq', 'gz'] }];
      case 'bam':
      case 'ubam':
        return [{ name: 'BAM files', extensions: ['bam'] }];
      case 'vcf':
        return [{ name: 'VCF files', extensions: ['vcf'] }];
      default:
        return [];
    }
  },
  filterByKey<T, K extends keyof T>(
    raw: T,
    callback: (k: keyof T) => boolean
  ): Omit<T, K> {
    return Object.keys(raw)
      .filter((k) => callback(k as keyof T))
      .reduce((obj, key) => {
        return {
          ...obj,
          [key]: raw[key as keyof T],
        };
      }, {}) as unknown as Omit<T, K>;
  },
  toArray<T>(list: unknown): T[] {
    return Array.prototype.slice.call(list || [], 0) as unknown as T[];
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
  async waitExists(filePath: string, timeout = 0): Promise<void> {
    return new Promise<void>((resolve, reject) => {
      let timer: ReturnType<typeof setTimeout> | null = null;
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
  hasPathProperty<X extends {}, Y extends PropertyKey>(
    obj: X,
    prop: Y
  ): obj is X & Record<Y, JobPath> {
    return (
      has(obj, prop) && has(obj, `${prop}.path`) && has(obj, `${prop}.url`)
    );
  },
};
