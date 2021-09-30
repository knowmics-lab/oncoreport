import { createTheme } from '@material-ui/core/styles';

const theme = createTheme({
  palette: {
    primary: {
      main: '#7d4709',
    },
    secondary: {
      main: '#fffaf2',
    },
  },
  overrides: {
    MuiListItem: {
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
    MuiListItemIcon: {
      root: {
        minWidth: 48,
      },
    },
  },
});

export default theme;
