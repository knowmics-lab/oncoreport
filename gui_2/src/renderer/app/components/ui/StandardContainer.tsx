import React, { useContext } from 'react';
import Paper from '@mui/material/Paper';
import ThemeContext from '../../themeContext';

type Props = React.PropsWithChildren<{
  sx?: Parameters<typeof Paper>[0]['sx'];
}>;

export default function StandardContainer({ children, sx }: Props) {
  const isDark = useContext(ThemeContext);
  return (
    <Paper
      elevation={isDark ? 0 : 1}
      sx={{
        px: 4,
        py: 2,
        borderRadius: 4,
        ...(sx ?? {}),
      }}
    >
      {children}
    </Paper>
  );
}
