import { ipcRenderer } from 'electron';
import { useContext, useEffect } from 'react';
import { ImageList, ImageListItem } from '@mui/material';
import MenuIcon from '@mui/icons-material/Menu';
import Typography from '@mui/material/Typography';
import Box from '@mui/material/Box';
import UNICT_LOGO from '../../../resources/unict.png';
import { StartedContext } from '../components/layout/appStartedContext';
import useCapabilities from '../hooks/useCapabilities';
import ThemeContext from '../themeContext';

export default function Home() {
  const { started } = useContext(StartedContext);
  const darkTheme = useContext(ThemeContext);
  const [loading, capabilities] = useCapabilities(!started);

  useEffect(() => {
    if (started) {
      if (loading) {
        ipcRenderer.send('display-blocking-message', {
          message: 'Loading...',
          error: false,
        });
      } else {
        setTimeout(() => {
          ipcRenderer.send('hide-blocking-message');
        }, 2000);
      }
    }
  }, [loading, started]);

  return (
    <>
      <Box component="section">
        <Typography variant="h4" gutterBottom sx={{ fontWeight: 'bold' }}>
          Oncoreport
        </Typography>
        <Typography gutterBottom>
          <b>{`You are using Oncoreport ${'XXXXX'} with the Oncoreport container v. ${
            capabilities ? capabilities.containerVersion : 'Loading...'
          }`}</b>
        </Typography>
        <Typography
          sx={{
            '> *': {
              display: 'inline',
              verticalAlign: 'middle',
            },
          }}
        >
          <span>
            Use the menu on the left to navigate through the application. If it
            is not visible, click on the hamburger button (
          </span>
          <MenuIcon />
          <span>) on the top left corner of the window.</span>
        </Typography>
      </Box>
      <Box
        component="section"
        sx={{
          textAlign: 'center',
          position: 'fixed',
          bottom: 0,
          marginBottom: (theme) => theme.spacing(1),
          width: '100% !important',
          '& img': {
            filter: darkTheme ? 'invert(1)' : 'invert(0)',
            transition: (theme) => theme.transitions.create('filter'),
          },
        }}
      >
        <ImageList rowHeight={55} cols={3}>
          <ImageListItem cols={1}>
            <img
              src={UNICT_LOGO}
              alt="UNICT"
              style={{ height: '100%', objectFit: 'contain' }}
            />
          </ImageListItem>
        </ImageList>
      </Box>
    </>
  );
}
