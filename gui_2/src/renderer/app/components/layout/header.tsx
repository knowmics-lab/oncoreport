import React from 'react';
import { Grid, styled } from '@mui/material';
import APP_LOGO from '../../../resources/logoOncoReport.png';

const Spacer = styled('div')({
  flexGrow: 1,
});

export default function Header() {
  // <Typography noWrap color="textSecondary" className={classes.header} />
  return (
    <Grid container justifyContent="center" alignItems="center">
      <img
        src={APP_LOGO}
        alt="OncoReport"
        style={{ height: '32px', width: 'auto' }}
      />
      <Spacer />
    </Grid>
  );
}
