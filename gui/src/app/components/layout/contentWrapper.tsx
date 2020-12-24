import React from 'react';
import { makeStyles } from '@material-ui/core/styles';

const useStyles = makeStyles(({ breakpoints, transitions }) => ({
  root: {
    padding: 16,
    transition: transitions.create([]),
    [breakpoints.up('sm')]: {
      padding: 24,
      maxWidth: 700,
      margin: 'auto',
    },
    [breakpoints.up('md')]: {
      maxWidth: 960,
    },
  },
}));

type Props = {
  children: React.ReactNode;
};

export default function ContentWrapper({ children }: Props) {
  const classes = useStyles();
  return <div className={classes.root}>{children}</div>;
}
