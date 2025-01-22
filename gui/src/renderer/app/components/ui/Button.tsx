/* eslint-disable react/no-unstable-nested-components */
import React from 'react';
import {
  Link as RouterLink,
  LinkProps as RouterLinkProps,
} from 'react-router-dom';
import { Button as MuiButton } from '@mui/material';
import CircularProgress from '@mui/material/CircularProgress';
import { ButtonOwnProps } from '@mui/material/Button/Button';
import Box from '@mui/material/Box';
import styles from '../../pages/styles';

type ButtonProps = {
  color?: ButtonOwnProps['color'];
  children: React.ReactNode;
  disabled?: boolean;
  href?: string;
  size?: ButtonOwnProps['size'];
  variant?: ButtonOwnProps['variant'];
  onClick?: () => void;
};

const LinkBehavior = React.forwardRef<
  HTMLAnchorElement,
  Omit<RouterLinkProps, 'to'> & { href: RouterLinkProps['to'] }
>((props, ref) => {
  const { href, ...other } = props;
  // Map href (Material UI) -> to (react-router)
  return <RouterLink ref={ref} to={href} {...other} />;
});

export default function Button({ href, onClick, ...props }: ButtonProps) {
  if (onClick) {
    return <MuiButton onClick={onClick} {...props} />;
  }
  return <MuiButton href={href} component={LinkBehavior} {...props} />;
}

Button.defaultProps = {
  color: 'secondary',
  size: 'medium',
  variant: 'text',
  disabled: false,
  href: null,
  onClick: null,
};

type SubmitButtonProps = {
  isSaving: boolean;
  text?: string;
};

export function SubmitButton({ isSaving, text }: SubmitButtonProps) {
  return (
    <Box component="div" sx={styles.buttonWrapper}>
      <MuiButton
        type="submit"
        variant="contained"
        color="primary"
        disabled={isSaving}
      >
        {text || 'Save'}
      </MuiButton>
      {isSaving && <CircularProgress size={24} sx={styles.buttonProgress} />}
    </Box>
  );
}

SubmitButton.defaultProps = {
  text: 'Save',
};
