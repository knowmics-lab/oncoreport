import React, { ReactNode, useState } from 'react';
import {
  Backdrop,
  CircularProgress,
  createStyles,
  makeStyles,
} from '@material-ui/core';
import fs from 'fs';
import { ipcRenderer } from 'electron';
import { Settings, Utils, ValidateConfig } from '../../../api';
import { useContainer, useService } from '../../../reactInjector';
import { ApiProtocol } from '../../../interfaces';
import { runAsync } from '../utils';

const useStyles = makeStyles((theme) =>
  createStyles({
    messageContainer: {
      display: 'flex',
      flexDirection: 'column',
      alignItems: 'center',
    },
    backdrop: {
      zIndex: theme.zIndex.drawer + 1,
      color: '#fff',
    },
  }),
);

type Props = { children: ReactNode | undefined };
type BackdropState = {
  shown?: boolean;
  message?: ReactNode;
  spinner?: boolean;
};

export default function ConfigUploader({ children }: Props) {
  const classes = useStyles();
  const [backdropState, setBackdropState] = useState<BackdropState>({});
  const settings = useService(Settings);
  const container = useContainer();

  const handleHideMessage = (e: React.DragEvent<HTMLElement>) => {
    e.preventDefault();
    setBackdropState({});
  };

  const handleShowMessage = (e: React.DragEvent<HTMLElement>) => {
    e.preventDefault();
    setBackdropState({
      shown: true,
      message: (
        <div className={classes.messageContainer}>
          <i className="fas fa-4x fa-fw fa-upload" />
          <h2>Drop a configuration file here to continue.</h2>
        </div>
      ),
    });
  };

  const handleDrop = (e: React.DragEvent<HTMLElement>) => {
    e.preventDefault();
    const filesArray = Utils.toArray<File>(e.dataTransfer.files);
    if (filesArray.length > 0 && filesArray[0]) {
      setBackdropState({
        shown: true,
        spinner: true,
      });
      const { path } = filesArray[0];
      fs.readFile(path, (err, data) => {
        if (err) {
          setBackdropState({});
          return;
        }
        runAsync(async () => {
          try {
            const {
              apiProtocol,
              apiHostname,
              apiPort,
              apiPath,
              publicPath,
              apiKey,
            } = JSON.parse(data.toString());
            setBackdropState({
              shown: true,
              message: <h2>Validating configuration...</h2>,
            });
            const validator = container.resolve(ValidateConfig);
            validator.newConfig = {
              apiHostname: `${apiHostname}`,
              apiKey: `${apiKey}`,
              apiPath: `${apiPath}`,
              apiPort: parseInt(apiPort, 10),
              apiProtocol:
                apiProtocol === 'https' ? ApiProtocol.https : ApiProtocol.http,
              autoStopDockerOnClose: false,
              configured: true,
              containerName: '',
              dataPath: '',
              local: false,
              publicPath: `${publicPath}`,
              socketPath: '',
            };
            const newConfig = await validator.validate((m) => {
              setBackdropState({
                shown: true,
                message: <h2>{m}</h2>,
              });
            });
            setBackdropState({
              shown: true,
              message: <h2>Configuration completed! Reloading the app...</h2>,
            });
            settings.saveConfig(newConfig);
            settings.saveConfig(newConfig);
            ipcRenderer.send('relaunch-app');
          } catch (_e) {
            setBackdropState({});
          }
        });
      });
    }
    return false;
  };

  return (
    <div
      onDragOver={handleShowMessage}
      onDragEnter={(e) => e.preventDefault()}
      onDragLeave={(e) => e.preventDefault()}
      onDragEnd={handleHideMessage}
      onDrop={handleDrop}
    >
      {children}
      <Backdrop className={classes.backdrop} open={!!backdropState.shown}>
        <div className={classes.messageContainer}>
          {backdropState.spinner && <CircularProgress color="inherit" />}
          {backdropState.message}
        </div>
      </Backdrop>
    </div>
  );
}
