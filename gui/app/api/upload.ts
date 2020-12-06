import uniqid from 'uniqid';
import { is } from 'electron-util';
import { ipcRenderer } from 'electron';
import cpFile, { ProgressData } from 'cp-file';
import { UsesUpload } from '../interfaces/ui';
import { UploadProgressFunction } from '../interfaces/common';
import { Job } from '../interfaces/jobs';
import * as Api from './index';

const registeredCallbacks = new Map();

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
      if (registeredCallbacks.has(id)) {
        const { resolve, reject, onProgress } = registeredCallbacks.get(id);
        if (isDone) {
          registeredCallbacks.delete(id);
          resolve();
        } else if (isError) {
          reject(new Error(error));
        } else if (isProgress) {
          onProgress(percentage, bytesUploaded, bytesTotal);
        }
      }
    }
  );
}
const makeLocalOnProgress = (onProgress?: UploadProgressFunction) => {
  let oldPercent = 0;
  return ({ size, writtenBytes, percent }: ProgressData) => {
    const percentRound = Math.round(percent * 100);
    if (percentRound >= oldPercent + 1) {
      if (onProgress) {
        onProgress(percentRound, writtenBytes, size);
      }
      oldPercent = percentRound;
    }
  };
};

export default {
  async localCopy(
    job: number | Job,
    filePath: string,
    fileName: string,
    onProgress?: UploadProgressFunction
  ): Promise<void> {
    await cpFile(filePath, `${Api.Jobs.getLocalDirectory(job)}/${fileName}`).on(
      'progress',
      makeLocalOnProgress(onProgress)
    );
  },
  async upload(
    job: number | Job,
    filePath: string,
    fileName: string,
    fileType: string,
    onProgress?: UploadProgressFunction
  ): Promise<void> {
    if (Api.Settings.isLocal()) {
      return this.localCopy(job, filePath, fileName, onProgress);
    }
    const endpoint = Api.Jobs.getUploadUrl(job);
    return new Promise((resolve, reject) => {
      const id = uniqid();
      registeredCallbacks.set(id, {
        resolve,
        reject,
        onProgress: (a: number, b: number, c: number) => {
          if (onProgress) onProgress(a, b, c);
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
  },
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
