import React from 'react';
import { CircularProgress, Grid } from '@mui/material';

interface LoadingSectionProps {
  loading: boolean;
  children: React.ReactNode | (() => React.ReactNode);
}

export default function LoadingSection({
  loading,
  children,
}: LoadingSectionProps) {
  // eslint-disable-next-line no-nested-ternary
  if (!loading && typeof children === 'function') return children();
  if (!loading && typeof children !== 'function') return children;

  return (
    <>
      <Grid container justifyContent="center">
        <Grid item xs="auto">
          <CircularProgress color="inherit" />
        </Grid>
      </Grid>
      <Grid container justifyContent="center">
        <Grid item xs="auto">
          Please wait...
        </Grid>
      </Grid>
    </>
  );
}
