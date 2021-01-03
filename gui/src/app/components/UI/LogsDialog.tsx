/* eslint-disable no-nested-ternary */
import React, { createRef, useEffect, useState } from 'react';
import Button from '@material-ui/core/Button';
import Dialog from '@material-ui/core/Dialog';
import DialogActions from '@material-ui/core/DialogActions';
import DialogContent from '@material-ui/core/DialogContent';
import DialogTitle from '@material-ui/core/DialogTitle';
import useMediaQuery from '@material-ui/core/useMediaQuery';
import { useTheme } from '@material-ui/core/styles';
import { TextField } from '@material-ui/core';
import InputAdornment from '@material-ui/core/InputAdornment';
import CircularProgress from '@material-ui/core/CircularProgress';
import Icon from '@material-ui/core/Icon';
import { JobEntity } from '../../../api';
import { JobStatus } from '../../../interfaces';
import { runAsync } from '../utils';

type LogsDialogProps = {
  job?: JobEntity;
  open: boolean;
  onClose: () => void;
};

export default function LogsDialog({ job, open, onClose }: LogsDialogProps) {
  const theme = useTheme();
  const fullScreen = useMediaQuery(theme.breakpoints.down('md'));
  const logRef = createRef<HTMLDivElement>();
  const [log, setLog] = useState<string>('');
  const [timeout, setTimeout] = useState(30);
  const isOpen = !!job && open;
  const needsRefresh = job && job.status === JobStatus.processing;

  useEffect(() => {
    if (job) {
      runAsync(async () => {
        setLog((await job.refresh()).log || '');
      });
    }
  }, [job]);

  useEffect(() => {
    let t: ReturnType<typeof setInterval> | undefined;
    if (job && needsRefresh && isOpen) {
      t = setInterval(async () => {
        setLog((await job.refresh()).log || '');
      }, timeout * 1000);
    }
    return () => {
      if (t) clearInterval(t);
    };
  }, [isOpen, job, needsRefresh, timeout]);

  useEffect(() => {
    if (needsRefresh && logRef.current) {
      logRef.current.scrollIntoView({ behavior: 'smooth' });
    }
  }, [logRef, needsRefresh]);

  return (
    <Dialog fullScreen={fullScreen} open={isOpen} onClose={onClose}>
      <DialogTitle>{job ? `Logs of ${job.name}` : 'Logs'}</DialogTitle>
      <DialogContent>
        {job ? (
          <>
            <pre>{log}</pre>
            <div ref={logRef} />
          </>
        ) : (
          <div style={{ textAlign: 'center' }}>
            <CircularProgress />
          </div>
        )}
      </DialogContent>
      <DialogActions>
        {needsRefresh && (
          <>
            <Icon className="fas fa-sync fa-spin" />
            <TextField
              label="Refresh every"
              variant="filled"
              value={timeout}
              onChange={(e) => setTimeout(() => +e.target.value)}
              onBlur={(e) => setTimeout(() => +e.target.value)}
              InputProps={{
                endAdornment: <InputAdornment position="end">s</InputAdornment>,
              }}
            />
          </>
        )}
        <Button onClick={onClose} color="primary" autoFocus>
          Close
        </Button>
      </DialogActions>
    </Dialog>
  );
}

LogsDialog.defaultProps = {
  job: undefined,
};
