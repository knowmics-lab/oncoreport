import { createStyles, makeStyles } from '@material-ui/core/styles';
import { green } from '@material-ui/core/colors';

const useStyles = makeStyles((theme) =>
  createStyles({
    paper: {
      padding: 0,
      borderRadius: 10,
    },
    appbar: {
      borderTopLeftRadius: 10,
      borderTopRightRadius: 10,
    },
    formControl: {
      margin: theme.spacing(1),
      minWidth: 120,
    },
    buttonWrapper: {
      margin: theme.spacing(1),
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
      zIndex: theme.zIndex.drawer + 1,
      color: '#fff',
    },
    topSeparation: {
      marginTop: theme.spacing(2),
    },
    bottomSeparation: {
      marginBottom: theme.spacing(2),
    },
    stickyStyle: {
      backgroundColor: theme.palette.background.default,
    },
  }),
);

export default useStyles;
