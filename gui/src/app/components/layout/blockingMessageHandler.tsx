import React, { useEffect, useState } from 'react';
import { ipcRenderer } from 'electron';
import ErrorIcon from '@material-ui/icons/Error';
import {
  createStyles,
  makeStyles,
  Backdrop,
  Typography,
  CircularProgress,
  Paper,
  Grid,
} from '@material-ui/core';

const useStyles = makeStyles((theme) =>
  createStyles({
    backdrop: {
      zIndex: theme.zIndex.drawer + 10,
      color: '#fff',
    },
    paper: {
      padding: 10,
    },
  })
);

const LogHandler = () => {
  const [log, setLog] = useState('');

  useEffect(() => {
    ipcRenderer.on('on-blocking-message-log', (_e, newState: string) => {
      setLog((prevState) => {
        if (prevState === newState) return prevState;
        return newState;
      });
    });
    return () => {
      ipcRenderer.removeAllListeners('on-blocking-message-log');
    };
  }, []);
  return <>{log ? <pre>{log}</pre> : null}</>;
};

export default function BlockingMessageHandler() {
  const classes = useStyles();
  const [state, setState] = useState({
    error: false,
    message: '',
    waiting: false,
  });

  useEffect(() => {
    ipcRenderer.on('on-display-blocking-message', (_e, { message, error }) =>
      setState({
        message,
        error,
        waiting: true,
      })
    );

    ipcRenderer.on('on-hide-blocking-message', () =>
      setState({
        message: '',
        error: false,
        waiting: false,
      })
    );
    return () => {
      ipcRenderer.removeAllListeners('on-display-blocking-message');
      ipcRenderer.removeAllListeners('on-hide-blocking-message');
    };
  });

  const { message, error, waiting } = state;
  return (
    <>
      <Backdrop className={classes.backdrop} open={waiting}>
        <Paper elevation={3} className={classes.paper}>
          <Grid container direction="column" alignItems="center">
            {error ? (
              <ErrorIcon fontSize="large" color="secondary" />
            ) : (
              <CircularProgress color="inherit" />
            )}
            <Typography
              variant="h6"
              component="div"
              color={error ? 'secondary' : 'inherit'}
            >
              {message}
            </Typography>
            <LogHandler />
          </Grid>
        </Paper>
      </Backdrop>
    </>
  );
}
