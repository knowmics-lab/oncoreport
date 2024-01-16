import { Theme } from '@mui/material/styles';
import { green } from '@mui/material/colors';

const styles = {
  paper: {
    padding: 0,
    borderRadius: 10,
  },
  appbar: {
    borderTopLeftRadius: 10,
    borderTopRightRadius: 10,
  },
  formControl: {
    margin: (theme: Theme) => theme.spacing(1),
    minWidth: 120,
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
    marginTop: -12,
    marginLeft: -12,
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
};

export default styles;
