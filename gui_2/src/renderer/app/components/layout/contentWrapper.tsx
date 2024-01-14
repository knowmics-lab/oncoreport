import React from 'react';
import { Container, Toolbar } from '@mui/material';
import Box from '@mui/material/Box';

type Props = {
  children: React.ReactNode;
};

export default function ContentWrapper({ children }: Props) {
  return (
    <Box
      component="main"
      sx={{
        backgroundColor: (th) =>
          th.palette.mode === 'light'
            ? th.palette.grey[100]
            : th.palette.grey[900],
        flexGrow: 1,
        height: '100vh',
        overflow: 'auto',
      }}
    >
      <Toolbar />
      <Container
        maxWidth="lg"
        sx={{
          mt: 4,
          mb: 4,
        }}
      >
        {children}
      </Container>
    </Box>
  );
}
