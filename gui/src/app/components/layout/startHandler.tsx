/* eslint-disable react-hooks/exhaustive-deps */
import React from 'react';
import { ipcRenderer } from 'electron';
import { useService } from '../../../reactInjector';
import { DockerManager, Settings } from '../../../api';

export default function StartHandler() {
  const settings = useService(Settings);
  const manager = useService(DockerManager);
  const [first, setFirst] = React.useState(false);

  React.useEffect(() => {
    if (!first) {
      if (settings.isConfigured() && settings.isLocal()) {
        const sendMessage = (message: string, error: boolean) =>
          ipcRenderer.send('display-blocking-message', {
            message,
            error,
          });
        const showLog = (log: string) =>
          ipcRenderer.send('blocking-message-log', log);
        manager
          .startupSequence(sendMessage, showLog)
          .then(() => ipcRenderer.send('hide-blocking-message'))
          .catch((e) => sendMessage(e.message, true));
      }
      setFirst(true);
    }
  }, []);

  return <></>;
}
