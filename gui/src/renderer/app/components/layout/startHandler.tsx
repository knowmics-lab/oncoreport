/* eslint-disable react-hooks/exhaustive-deps */
import React, { useContext } from 'react';
import { ipcRenderer } from 'electron';
import { useService } from '../../../../reactInjector';
import { DockerManager, Settings, OncoKb } from '../../../../api';
import { StartedContext } from './appStartedContext';

export default function StartHandler() {
  const settings = useService(Settings);
  const manager = useService(DockerManager);
  const oncokb = useService(OncoKb);
  const { setStarted } = useContext(StartedContext);
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
          .then(() => oncokb.readConfig())
          .then(() => ipcRenderer.send('hide-blocking-message'))
          .finally(() => setStarted(true))
          .catch((e) => sendMessage(e.message, true));
      } else {
        setStarted(true);
      }
      setFirst(true);
    }
  }, []);

  // eslint-disable-next-line react/jsx-no-useless-fragment
  return <></>;
}
