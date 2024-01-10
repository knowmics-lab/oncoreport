import { useState } from 'react';
import {
  UploadCallbacks,
  UploadHook,
  UploadProgressFunction,
  UploadState,
} from '../../interfaces';

export default function useUpload(): UploadHook {
  const [state, setState] = useState<UploadState>({
    isUploading: false,
    uploadFile: '',
    uploadedBytes: 0,
    uploadedPercent: 0,
    uploadTotal: 0,
  });
  const uploadCallbacks: UploadCallbacks = {
    uploadStart(uploadFile: string) {
      setState({
        isUploading: true,
        uploadFile,
        uploadedBytes: 0,
        uploadedPercent: 0,
        uploadTotal: 0,
      });
    },
    uploadEnd() {
      setState({
        isUploading: false,
        uploadFile: '',
        uploadedBytes: 0,
        uploadedPercent: 0,
        uploadTotal: 0,
      });
    },
    makeOnProgress(): UploadProgressFunction {
      return (uploadedPercent, uploadedBytes, uploadTotal) =>
        setState((prevState) => ({
          ...prevState,
          uploadedPercent,
          uploadedBytes,
          uploadTotal,
        }));
    },
  };
  return [state, uploadCallbacks, setState];
}
