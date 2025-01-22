import React, { MouseEventHandler } from 'react';
import CheckCircleIcon from '@mui/icons-material/CheckCircle';
import ErrorIcon from '@mui/icons-material/Error';
import InfoIcon from '@mui/icons-material/Info';
import CloseIcon from '@mui/icons-material/Close';
import { amber, green } from '@mui/material/colors';
import IconButton from '@mui/material/IconButton';
import {
  Snackbar as MaterialSnackbar,
  SnackbarCloseReason,
  Alert,
} from '@mui/material';
import SnackbarContent from '@mui/material/SnackbarContent';
import WarningIcon from '@mui/icons-material/Warning';
import { TypeOfNotification } from '../../../../interfaces';
import theme from '../../theme';

const variantIcon = {
  [TypeOfNotification.success]: CheckCircleIcon,
  [TypeOfNotification.warning]: WarningIcon,
  [TypeOfNotification.error]: ErrorIcon,
  [TypeOfNotification.info]: InfoIcon,
};

const variantStyle = (variant: TypeOfNotification) => {
  switch (variant) {
    case TypeOfNotification.success:
      return {
        backgroundColor: green[600],
      };
    case TypeOfNotification.error:
      return {
        backgroundColor: theme.palette.error.dark,
      };
    case TypeOfNotification.info:
      return {
        backgroundColor: theme.palette.primary.main,
      };
    case TypeOfNotification.warning:
      return {
        backgroundColor: amber[700],
      };
    default:
      return {};
  }
};

type ContentWrapperProps = {
  message: string;
  onClose?: MouseEventHandler;
  variant: TypeOfNotification;
};

function ContentWrapper({ message, onClose, variant }: ContentWrapperProps) {
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
        <CloseIcon sx={{ fontSize: 20 }} />
      </IconButton>,
    );
  }

  return (
    <SnackbarContent
      sx={variantStyle(variant)}
      message={
        <span
          style={{
            display: 'flex',
            alignItems: 'center',
          }}
        >
          <Icon
            sx={(t) => ({
              fontSize: 20,
              opacity: 0.9,
              marginRight: t.spacing(1),
            })}
          />
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
  const onClose = (_e: unknown, reason?: SnackbarCloseReason) => {
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
