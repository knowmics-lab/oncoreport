import React, { useEffect, useState } from 'react';
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

const Backdrop = styled(OriginalBackdrop)(({ theme }) => ({
  zIndex: theme.zIndex.drawer + 10,
  color: '#fff',
}));

const Paper = styled(OriginalPaper)({
  padding: 10,
});

function LogHandler() {
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
  return log ? (
    <pre style={{ maxHeight: '400px', overflow: 'auto' }}>{log}</pre>
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
