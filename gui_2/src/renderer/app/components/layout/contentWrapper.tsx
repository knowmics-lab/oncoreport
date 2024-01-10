import React from 'react';
import { Paper as OriginalPaper, styled } from '@mui/material';

const Paper = styled(OriginalPaper)(({ theme }) => ({
  padding: 16,
  transition: theme.transitions.create([]),
  [theme.breakpoints.up('sm')]: {
    padding: 24,
    maxWidth: 700,
    margin: 'auto',
  },
  [theme.breakpoints.up('md')]: {
    maxWidth: 960,
  },
}));

type Props = {
  children: React.ReactNode;
};

export default function ContentWrapper({ children }: Props) {
  return <Paper elevation={0}>{children}</Paper>;
}
