import React, { MouseEventHandler, SyntheticEvent } from 'react';
import clsx from 'clsx';
import CheckCircleIcon from '@material-ui/icons/CheckCircle';
import ErrorIcon from '@material-ui/icons/Error';
import InfoIcon from '@material-ui/icons/Info';
import CloseIcon from '@material-ui/icons/Close';
import { amber, green } from '@material-ui/core/colors';
import IconButton from '@material-ui/core/IconButton';
import {
  Snackbar as MaterialSnackbar,
  SnackbarCloseReason,
} from '@material-ui/core';
import SnackbarContent from '@material-ui/core/SnackbarContent';
import WarningIcon from '@material-ui/icons/Warning';
import { makeStyles } from '@material-ui/core/styles';
import { Alert } from '@material-ui/lab';
import { TypeOfNotification } from '../../../interfaces';

const variantIcon = {
  [TypeOfNotification.success]: CheckCircleIcon,
  [TypeOfNotification.warning]: WarningIcon,
  [TypeOfNotification.error]: ErrorIcon,
  [TypeOfNotification.info]: InfoIcon,
};

const useStylesWrapper = makeStyles((theme) => ({
  success: {
    backgroundColor: green[600],
  },
  error: {
    backgroundColor: theme.palette.error.dark,
  },
  info: {
    backgroundColor: theme.palette.primary.main,
  },
  warning: {
    backgroundColor: amber[700],
  },
  icon: {
    fontSize: 20,
  },
  iconVariant: {
    opacity: 0.9,
    marginRight: theme.spacing(1),
  },
  message: {
    display: 'flex',
    alignItems: 'center',
  },
}));

type ContentWrapperProps = {
  message: string;
  onClose?: MouseEventHandler;
  variant: TypeOfNotification;
};

function ContentWrapper({ message, onClose, variant }: ContentWrapperProps) {
  const classes = useStylesWrapper();
  const Icon = variantIcon[variant];
  const actions = [];
  if (onClose) {
    actions.push(
      <IconButton
        key="close"
        aria-label="close"
        color="inherit"
        onClick={onClose}
      >
        <CloseIcon className={classes.icon} />
      </IconButton>,
    );
  }

  return (
    <SnackbarContent
      className={clsx(classes[variant])}
      message={
        <span className={classes.message}>
          <Icon className={clsx(classes.icon, classes.iconVariant)} />
          {message}
        </span>
      }
      action={actions}
    />
  );
}

ContentWrapper.defaultProps = {
  onClose: () => {},
};

export type SnackbarProps = {
  message: string;
  isOpen: boolean;
  setClosed: () => void;
  variant: TypeOfNotification;
  duration?: number;
  anchorVertical?: 'top' | 'bottom';
  anchorHorizontal?: 'left' | 'center' | 'right';
};

export default function Snackbar({
  message,
  isOpen,
  setClosed,
  variant,
  duration,
  anchorVertical,
  anchorHorizontal,
}: SnackbarProps) {
  const onClose = (_e: SyntheticEvent, reason?: SnackbarCloseReason) => {
    if (reason === 'clickaway') {
      return;
    }
    setClosed();
  };

  return (
    <MaterialSnackbar
      anchorOrigin={{
        vertical: anchorVertical || 'bottom',
        horizontal: anchorHorizontal || 'left',
      }}
      open={isOpen}
      autoHideDuration={duration}
      onClose={onClose}
    >
      <Alert variant="filled" onClose={onClose} severity={variant}>
        {message}
      </Alert>
    </MaterialSnackbar>
  );
}

Snackbar.defaultProps = {
  duration: 3000,
  anchorVertical: 'bottom',
  anchorHorizontal: 'left',
};
