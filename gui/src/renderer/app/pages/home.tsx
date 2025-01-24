/* eslint-disable react/no-array-index-key */
import { ipcRenderer } from 'electron';
import { useContext, useEffect, useMemo } from 'react';
import { ImageList, ImageListItem } from '@mui/material';
import MenuIcon from '@mui/icons-material/Menu';
import Typography from '@mui/material/Typography';
import Box from '@mui/material/Box';
import { green, orange, red } from '@mui/material/colors';
import Table from '@mui/material/Table';
import TableBody from '@mui/material/TableBody';
import TableCell from '@mui/material/TableCell';
import TableContainer from '@mui/material/TableContainer';
import TableHead from '@mui/material/TableHead';
import TableRow from '@mui/material/TableRow';
import Paper from '@mui/material/Paper';
import { Capabilities } from '../../../api/utils';
import SysConstants from '../../../constants/system.json';
import ThemeContext from '../themeContext';
import useCapabilities from '../hooks/useCapabilities';
import { StartedContext } from '../components/layout/appStartedContext';
import UNICT_LOGO from '../../../resources/unict.png';
import IOM_LOGO from '../../../resources/iom.png';
import THE_LOGO from '../../../resources/the.png';
import DIONCOGEN_LOGO from '../../../resources/dioncogen.png';

type InternalProps = { capabilities: Capabilities };

function OncoKbTokenStatus({ capabilities }: InternalProps) {
  const darkTheme = useContext(ThemeContext);
  const color = useMemo(() => {
    if (capabilities.oncokbTokenStatus.status === 'ok') {
      return green[darkTheme ? 300 : 800];
    }
    if (capabilities.oncokbTokenStatus.status === 'warning') {
      return orange[darkTheme ? 300 : 800];
    }
    return red[darkTheme ? 300 : 800];
  }, [capabilities, darkTheme]);
  const fontSize = useMemo(() => {
    if (capabilities.oncokbTokenStatus.status === 'ok') {
      return 'small';
    }
    if (capabilities.oncokbTokenStatus.status === 'warning') {
      return 'medium';
    }
    return 'large';
  }, [capabilities]);
  return (
    <Typography
      sx={{
        fontWeight: 'bold',
        color,
      }}
      gutterBottom
      fontSize={fontSize}
    >
      {capabilities.oncokbTokenStatus.message}
    </Typography>
  );
}

function VersionsTable({ capabilities }: InternalProps) {
  const versions = capabilities.dbVersions;
  return (
    <>
      <Typography gutterBottom fontSize="small">
        You are currently using the following annotations databases:
      </Typography>
      <TableContainer
        component={Paper}
        sx={{
          display: 'flex',
          alignContent: 'center',
          justifyContent: 'center',
          '& *': {
            fontSize: 'small',
          },
          '& th': {
            fontWeight: 'bold',
          },
        }}
      >
        <Table size="small">
          <TableHead>
            <TableRow>
              <TableCell align="left">Database</TableCell>
              <TableCell>Version</TableCell>
              <TableCell>Download date</TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {versions.map(({ name, version, download_date }, index) => (
              <TableRow
                key={`${name}-${index}`}
                sx={{ '&:last-child td, &:last-child th': { border: 0 } }}
              >
                <TableCell component="th" scope="row" align="left">
                  {name}
                </TableCell>
                <TableCell>{version}</TableCell>
                <TableCell>{download_date}</TableCell>
              </TableRow>
            ))}
          </TableBody>
        </Table>
      </TableContainer>
    </>
  );
}

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
        <Typography gutterBottom fontSize="small">
          <b>{`You are using Oncoreport ${
            SysConstants.GUI_VERSION
          } with the Oncoreport container v. ${
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
          gutterBottom
          fontSize="small"
        >
          <span>
            Use the menu on the left to navigate through the application. If it
            is not visible, click on the menu button (
          </span>
          <MenuIcon />
          <span>) on the top left corner of the window.</span>
        </Typography>
        {capabilities && <OncoKbTokenStatus capabilities={capabilities} />}
        {capabilities && <VersionsTable capabilities={capabilities} />}
      </Box>
      <Box
        component="footer"
        sx={{
          marginBottom: (theme) => theme.spacing(1),
          '& img': {
            filter: darkTheme ? 'sepia(100%) invert(1)' : 'invert(0)',
            transition: (theme) => theme.transitions.create('filter'),
          },
        }}
      >
        <Typography sx={{ py: 2 }} fontSize="small">
          Oncoreport is a joint project by:
        </Typography>
        <ImageList rowHeight={55} cols={2}>
          <ImageListItem cols={1}>
            <img
              src={UNICT_LOGO}
              alt="University of Catania"
              style={{ height: '100%', objectFit: 'contain' }}
            />
          </ImageListItem>
          <ImageListItem cols={1}>
            <img
              src={IOM_LOGO}
              alt="IOM Ricerca"
              style={{ height: '100%', objectFit: 'contain' }}
            />
          </ImageListItem>
        </ImageList>
        <Typography sx={{ py: 2 }} fontSize="small">
          The first release of Oncoreport was funded by the &quot;DiOncoGen
          Diagnostica Innovativa&quot; project, funded under Action 1.1.5 of the
          POR FESR Sicilia 2014-2020.
        </Typography>
        <ImageList rowHeight={55} cols={3}>
          <ImageListItem cols={3}>
            <img
              src={DIONCOGEN_LOGO}
              alt="DiOncoGen Diagnostica Innovativa"
              style={{ height: '100%', objectFit: 'contain' }}
            />
          </ImageListItem>
        </ImageList>
        <Typography sx={{ py: 2 }} fontSize="small">
          The current release of Oncoreport is funded by the OMICANCER project,
          funded under the Tuscany Health Ecosystem (THE) and the Italian
          National Recovery and Resilience Plan (PNRR).
        </Typography>
        <ImageList rowHeight={55} cols={3}>
          <ImageListItem cols={3}>
            <img
              src={THE_LOGO}
              alt="The Tuscany Health Ecosystem"
              style={{ height: '100%', objectFit: 'contain' }}
            />
          </ImageListItem>
        </ImageList>
      </Box>
    </>
  );
}
