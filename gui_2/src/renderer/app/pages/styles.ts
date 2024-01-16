import { Theme } from '@mui/material/styles';
import { green } from '@mui/material/colors';

const styles = {
  paper: {
    padding: 0,
    borderRadius: '10px',
  },
  paperWithPadding: {
    px: 4,
    py: 2,
  },
  appbar: {
    borderTopLeftRadius: '10px',
    borderTopRightRadius: '10px',
  },
  formControl: {
    margin: (theme: Theme) => theme.spacing(1),
    minWidth: '120px',
  },
  buttonWrapper: {
    margin: (theme: Theme) => theme.spacing(1),
    position: 'relative',
  },
  buttonProgress: {
    color: green[500],
    position: 'absolute',
    top: '50%',
    left: '50%',
    marginTop: '-12px',
    marginLeft: '-12px',
  },
  backdrop: {
    zIndex: (theme: Theme) => theme.zIndex.drawer + 1,
    color: '#fff',
  },
  topSeparation: {
    marginTop: (theme: Theme) => theme.spacing(2),
  },
  bottomSeparation: {
    marginBottom: (theme: Theme) => theme.spacing(2),
  },
  stickyStyle: {
    backgroundColor: (theme: Theme) => theme.palette.background.default,
  },
  instructions: {
    marginTop: (theme: Theme) => theme.spacing(1),
    marginBottom: (theme: Theme) => theme.spacing(1),
    fontSize: (theme: Theme) => theme.typography.fontSize,
  },
};

export default styles;
