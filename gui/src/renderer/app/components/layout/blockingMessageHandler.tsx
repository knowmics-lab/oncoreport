/* eslint-disable react/no-danger */
import React, { createRef, useEffect, useState } from 'react';
import { ipcRenderer } from 'electron';
import ErrorIcon from '@mui/icons-material/Error';
import {
  Backdrop as OriginalBackdrop,
  Typography,
  CircularProgress,
  Paper as OriginalPaper,
  Grid,
  styled,
} from '@mui/material';
import { logToHtml } from '../utils';

const Backdrop = styled(OriginalBackdrop)(({ theme }) => ({
  zIndex: theme.zIndex.drawer + 10,
  color: '#fff',
}));

const Paper = styled(OriginalPaper)({
  padding: 10,
});

function LogHandler() {
  const [log, setLog] = useState('');
  const logRef = createRef<HTMLDivElement>();

  useEffect(() => {
    if (log && logRef.current) {
      logRef.current.scrollIntoView({ behavior: 'smooth' });
    }
  }, [log, logRef]);

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
  return log ? (
    <div
      style={{
        width: '100%',
        maxHeight: '400px',
        overflowY: 'auto',
      }}
    >
      <div
        style={{
          fontFamily: "'Courier New', monospace",
          color: 'white',
          background: 'black',
          wordBreak: 'break-all',
        }}
        dangerouslySetInnerHTML={{ __html: logToHtml(log) }}
      />
      <div ref={logRef} />
    </div>
  ) : null;
}

export default function BlockingMessageHandler() {
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
      }),
    );

    ipcRenderer.on('on-hide-blocking-message', () =>
      setState({
        message: '',
        error: false,
        waiting: false,
      }),
    );
    return () => {
      ipcRenderer.removeAllListeners('on-display-blocking-message');
      ipcRenderer.removeAllListeners('on-hide-blocking-message');
    };
  });

  const { message, error, waiting } = state;
  return (
    <Backdrop open={waiting}>
      <Paper elevation={3}>
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
  );
}
