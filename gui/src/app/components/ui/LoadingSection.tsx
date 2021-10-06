import React from 'react';
import { CircularProgress, Grid } from '@material-ui/core';

interface LoadingSectionProps {
  loading: boolean;
  children: React.ReactNode | (() => React.ReactNode);
}

export default function LoadingSection({
  loading,
  children,
}: LoadingSectionProps) {
  return (
    <>
      {loading ? (
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
      ) : (
        <>{typeof children === 'function' ? children() : children}</>
      )}
    </>
  );
}
