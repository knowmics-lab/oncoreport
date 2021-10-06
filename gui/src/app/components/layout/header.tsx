import React from 'react';
import { createStyles, Grid, makeStyles } from '@material-ui/core';
import APP_LOGO from '../../../resources/logoOncoReport.png';

const useStyles = makeStyles(() =>
  createStyles({
    header: {
      fontWeight: 900,
      minWidth: 0,
      fontSize: 18,
    },
    grow: {
      flexGrow: 1,
    },
  })
);

export default function Header() {
  const classes = useStyles();
  // <Typography noWrap color="textSecondary" className={classes.header} />
  return (
    <>
      <Grid container justifyContent="center" alignItems="center">
        <img
          src={APP_LOGO}
          alt="OncoReport"
          style={{ height: '32px', width: 'auto' }}
        />
        <div className={classes.grow} />
      </Grid>
    </>
  );
}
