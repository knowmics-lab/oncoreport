import { BrowserWindow, ipcMain, ipcRenderer } from 'electron';
import { is } from 'electron-util';
import uniqid from 'uniqid';
import { singleton } from 'tsyringe';
import cpFile, { ProgressData } from 'cp-file';
import { debounce } from 'ts-debounce';
import { download } from 'electron-dl';
import * as tus from 'tus-js-client';
import fs from 'fs';
import type { UploadProgressFunction } from '../interfaces';
import { UsesUpload } from '../interfaces';
import Settings from './settings';
import { JobEntity } from './entities';

type UploadCallbackType = {
  resolve: () => void;
  reject: (e: Error) => void;
  onProgress: UploadProgressFunction;
};

@singleton()
export default class TransferManager {
  #rendererHandlersRegistered = false;

  #mainHandlersRegistered = false;

  readonly downloadStartCallbacks = new Map<string, () => void>();

  readonly downloadCompletedCallbacks = new Map<string, () => void>();

  readonly uploadCallbacks = new Map<string, UploadCallbackType>();

  readonly #settings: Settings;

  public constructor(settings: Settings) {
    this.registerRendererHandlers();
    this.#settings = settings;
  }

  private registerRendererHandlers() {
    if (!this.#rendererHandlersRegistered) {
      this.registerRendererDownloadHandlers();
      this.registerRendererUploadHandlers();
      this.#rendererHandlersRegistered = true;
    }
  }

  private registerRendererDownloadHandlers() {
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

  private registerRendererUploadHandlers() {
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

  public async upload(
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

  public registerMainHandlers(win: BrowserWindow) {
    if (!this.#mainHandlersRegistered) {
      this.registerMainDownloadHandler(win);
      this.registerMainUploadHandler();
      this.#mainHandlersRegistered = true;
    }
  }

  // eslint-disable-next-line class-methods-use-this
  public registerMainDownloadHandler(win: BrowserWindow) {
    if (is.main) {
      ipcMain.on('download-file', async (event, { id, url, filename }) => {
        await download(win, url, {
          saveAs: true,
          openFolderWhenDone: false,
          filename,
          onStarted() {
            event.reply('download-started', { id });
          },
          onProgress(progress) {
            if (progress.percent >= 1) {
              event.reply('download-completed', { id });
            }
          },
        });
      });
    }
  }

  public registerMainUploadHandler() {
    if (is.main) {
      ipcMain.on(
        'upload-file',
        async (event, { id, filePath, fileName, fileType, endpoint }) => {
          const file = fs.createReadStream(filePath);
          const { size } = fs.statSync(filePath);
          // resume: true,
          const upload = new tus.Upload(file, {
            endpoint,
            retryDelays: [0, 3000, 5000, 10000, 20000],
            headers: {
              ...this.#settings.getAuthHeaders(),
            },
            chunkSize: 50 * 1024 * 1024, // 50Mb per chunk
            metadata: {
              filename: fileName,
              filetype: fileType,
            },
            uploadSize: size,
            onError(error) {
              event.reply('upload-message', {
                id,
                isDone: false,
                isProgress: false,
                isError: true,
                percentage: 0,
                bytesUploaded: 0,
                bytesTotal: 0,
                error: error.message,
              });
            },
            onProgress(bytesUploaded, bytesTotal) {
              const percentage = Math.round((bytesUploaded / bytesTotal) * 100);
              event.reply('upload-message', {
                id,
                isDone: false,
                isProgress: true,
                isError: false,
                error: null,
                percentage,
                bytesUploaded,
                bytesTotal,
              });
            },
            onSuccess() {
              event.reply('upload-message', {
                id,
                isDone: true,
                isProgress: false,
                isError: false,
                error: null,
                percentage: 0,
                bytesUploaded: 0,
                bytesTotal: 0,
              });
            },
          });

          upload.start();
        }
      );
    }
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
