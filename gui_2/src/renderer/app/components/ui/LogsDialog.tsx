/* eslint-disable no-nested-ternary */
import React, { createRef, useEffect, useState } from 'react';
import Button from '@mui/material/Button';
import Dialog from '@mui/material/Dialog';
import DialogActions from '@mui/material/DialogActions';
import DialogContent from '@mui/material/DialogContent';
import DialogTitle from '@mui/material/DialogTitle';
import useMediaQuery from '@mui/material/useMediaQuery';
import { useTheme } from '@mui/material/styles';
import { TextField } from '@mui/material';
import InputAdornment from '@mui/material/InputAdornment';
import CircularProgress from '@mui/material/CircularProgress';
import Icon from '@mui/material/Icon';
import { JobEntity } from '../../../../api';
import { JobStatus } from '../../../../interfaces';
import { runAsync } from '../utils';
import useInterval from '../../hooks/useInterval';

type LogsDialogProps = {
  job?: JobEntity;
  open: boolean;
  onClose: () => void;
};

export default function LogsDialog({ job, open, onClose }: LogsDialogProps) {
  const theme = useTheme();
  const fullScreen = useMediaQuery(theme.breakpoints.down('md'));
  const logRef = createRef<HTMLDivElement>();
  const [loading, setLoading] = useState(false);
  const [log, setLog] = useState<string>('');
  const [timeout, setTimeout] = useState(30);
  const isOpen = !!job && open;
  const needsRefresh = job && !loading && job.status === JobStatus.processing;

  useEffect(() => {
    const observer = {
      refreshed: (entity: JobEntity) => setLog(entity.log ?? ''),
    };
    if (isOpen && job) {
      job.observe(observer);
    }
    return () => {
      if (job) job.removeObserver(observer);
    };
  }, [isOpen, job]);

  useEffect(() => {
    if (job) {
      setLoading(true);
      runAsync(async () => {
        await job.refresh();
        setLoading(false);
      });
    }
  }, [job]);

  useInterval(
    async () => {
      await job?.refresh();
    },
    job && needsRefresh && isOpen ? timeout * 1000 : undefined,
  );

  useEffect(() => {
    if (needsRefresh && logRef.current) {
      logRef.current.scrollIntoView({ behavior: 'smooth' });
    }
  }, [logRef, needsRefresh]);

  return (
    <Dialog
      fullScreen={fullScreen}
      open={isOpen}
      onClose={onClose}
      maxWidth="lg"
      scroll="paper"
      fullWidth
    >
      <DialogTitle>{job ? `Logs of ${job.name}` : 'Logs'}</DialogTitle>
      <DialogContent>
        {job && !loading ? (
          <>
            <pre>{log}</pre>
            <div ref={logRef} />
          </>
        ) : (
          <>
            <div style={{ textAlign: 'center' }}>
              <CircularProgress />
            </div>
            <div style={{ textAlign: 'center' }}>Please wait...</div>
          </>
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
        <Button onClick={onClose} color="primary" variant="contained" autoFocus>
          Close
        </Button>
      </DialogActions>
    </Dialog>
  );
}

LogsDialog.defaultProps = {
  job: undefined,
};
