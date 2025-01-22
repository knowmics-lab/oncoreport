import { createTheme } from '@mui/material';

const theme = createTheme({
  palette: {
    primary: {
      main: '#7d4709',
    },
    secondary: {
      main: '#fffaf2',
    },
  },
  components: {
    MuiListItem: {
      styleOverrides: {
        root: {
          '&.Mui-selected': {
            backgroundColor: '#7d4709',
            color: '#fff',
            '& svg': {
              color: '#fff',
            },
            '&:hover': {
              backgroundColor: '#95550b',
            },
          },
        },
      },
    },
    MuiListItemIcon: {
      styleOverrides: {
        root: {
          minWidth: 48,
        },
      },
    },
  },
});

export default theme;
