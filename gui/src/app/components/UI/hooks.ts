import { useState } from 'react';
import { Notifications as NotificationsManager } from '../../../api';
import { useService } from '../../../reactInjector';
import {
  UploadCallbacks,
  UploadHook,
  UploadProgressFunction,
  UploadState,
} from '../../../interfaces';

export function useNotifications() {
  const manager = useService(NotificationsManager);
  return {
    pushSimple: manager.pushSimple.bind(manager),
    push: manager.push.bind(manager),
    manager,
  };
}

export function useUpload(): UploadHook {
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
