import { ipcRenderer } from 'electron';
import { is } from 'electron-util';
import uniqid from 'uniqid';
import { singleton } from 'tsyringe';
import cpFile, { ProgressData } from 'cp-file';
import { debounce } from 'ts-debounce';
import { UploadProgressFunction } from '../interfaces/common';
import { UsesUpload } from '../interfaces/ui';
import Settings from './settings';
import { JobEntity } from './entities';

type UploadCallbackType = {
  resolve: () => void;
  reject: (e: Error) => void;
  onProgress: UploadProgressFunction;
};

@singleton()
export default class TransferManager {
  #handlersRegistered = false;

  readonly downloadStartCallbacks = new Map<string, () => void>();

  readonly downloadCompletedCallbacks = new Map<string, () => void>();

  readonly uploadCallbacks = new Map<string, UploadCallbackType>();

  readonly #settings: Settings;

  public constructor(settings: Settings) {
    this.registerHandlers();
    this.#settings = settings;
  }

  private registerHandlers() {
    if (!this.#handlersRegistered) {
      this.registerDownloadHandlers();
      this.registerUploadHandlers();
      this.#handlersRegistered = true;
    }
  }

  private registerDownloadHandlers() {
    if (is.renderer) {
      ipcRenderer.removeAllListeners('download-started');
      ipcRenderer.on('download-started', (_e, { id }) => {
        if (this.downloadStartCallbacks.has(id)) {
          const onStart = this.downloadStartCallbacks.get(id);
          if (typeof onStart === 'function') {
            onStart();
          }
        }
      });
      ipcRenderer.removeAllListeners('download-completed');
      ipcRenderer.on('download-completed', (_event, { id }) => {
        if (this.downloadCompletedCallbacks.has(id)) {
          const onCompleted = this.downloadCompletedCallbacks.get(id);
          if (typeof onCompleted === 'function') {
            onCompleted();
          }
          this.downloadCompletedCallbacks.delete(id);
        }
        if (this.downloadStartCallbacks.has(id)) {
          this.downloadStartCallbacks.delete(id);
        }
      });
    }
  }

  private registerUploadHandlers() {
    if (is.renderer) {
      ipcRenderer.removeAllListeners('upload-message');
      ipcRenderer.on(
        'upload-message',
        (
          _event,
          {
            id,
            isDone,
            isProgress,
            isError,
            error,
            percentage,
            bytesUploaded,
            bytesTotal,
          }
        ) => {
          if (this.uploadCallbacks.has(id)) {
            const callback = this.uploadCallbacks.get(id);
            if (callback) {
              const { resolve, reject, onProgress } = callback;
              if (isDone) {
                this.uploadCallbacks.delete(id);
                resolve();
              } else if (isError) {
                reject(new Error(error));
              } else if (isProgress) {
                onProgress(percentage, bytesUploaded, bytesTotal);
              }
            }
          }
        }
      );
    }
  }

  public download(
    url: string,
    filename: string,
    onStart?: () => void,
    onCompleted?: () => void
  ) {
    const id = uniqid();
    if (onStart) this.downloadStartCallbacks.set(id, onStart);
    if (onCompleted) this.downloadCompletedCallbacks.set(id, onCompleted);
    ipcRenderer.send('download-file', { id, url, filename });
  }

  private static makeLocalOnProgress(onProgress?: UploadProgressFunction) {
    // const oldPercent = 0;
    return debounce(({ size, writtenBytes, percent }: ProgressData) => {
      const percentRound = Math.round(percent * 100);
      // if (percentRound >= oldPercent + 1) {
      if (onProgress) {
        onProgress(percentRound, writtenBytes, size);
      }
      // oldPercent = percentRound;
      // }
    }, 250);
  }

  private static async localCopy(
    job: JobEntity,
    filePath: string,
    fileName: string,
    onProgress?: UploadProgressFunction
  ): Promise<void> {
    await cpFile(filePath, `${job.getLocalDirectory()}/${fileName}`).on(
      'progress',
      TransferManager.makeLocalOnProgress(onProgress)
    );
  }

  async upload(
    job: JobEntity,
    filePath: string,
    fileName: string,
    fileType: string,
    onProgress?: UploadProgressFunction
  ): Promise<void> {
    if (this.#settings.isLocal()) {
      return TransferManager.localCopy(job, filePath, fileName, onProgress);
    }
    const endpoint = job.getUploadUrl();
    return new Promise((resolve, reject) => {
      const id = uniqid();
      this.uploadCallbacks.set(id, {
        resolve,
        reject,
        onProgress: (
          percentage: number,
          bytesUploaded: number,
          bytesTotal: number
        ) => {
          if (onProgress) onProgress(percentage, bytesUploaded, bytesTotal);
        },
      });
      ipcRenderer.send('upload-file', {
        id,
        filePath,
        fileName,
        fileType,
        endpoint,
      });
    });
  }
}

// @todo this part should be moved from here
export const tmp = {
  ui: {
    initUploadState(): UsesUpload {
      return {
        isUploading: false,
        uploadFile: '',
        uploadedBytes: 0,
        uploadedPercent: 0,
        uploadTotal: 0,
      };
    },
    uploadStart(setState: (state: unknown) => void, uploadFile: string): void {
      setState({
        isUploading: true,
        uploadFile,
        uploadedBytes: 0,
        uploadedPercent: 0,
        uploadTotal: 0,
      });
    },
    uploadEnd(setState: (state: unknown) => void): void {
      setState({
        isUploading: false,
        uploadFile: '',
        uploadedBytes: 0,
        uploadedPercent: 0,
        uploadTotal: 0,
      });
    },
    makeOnProgress(setState: (state: unknown) => void): UploadProgressFunction {
      return (uploadedPercent, uploadedBytes, uploadTotal) =>
        setState({
          uploadedPercent,
          uploadedBytes,
          uploadTotal,
        });
    },
  },
};
