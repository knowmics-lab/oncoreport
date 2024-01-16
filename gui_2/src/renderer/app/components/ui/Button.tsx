/* eslint-disable react/no-unstable-nested-components */
import React from 'react';
import {
  Link as RouterLink,
  LinkProps as RouterLinkProps,
} from 'react-router-dom';
import { Button as MuiButton, styled } from '@mui/material';
import CircularProgress from '@mui/material/CircularProgress';
import { green } from '@mui/material/colors';
import { ButtonOwnProps } from '@mui/material/Button/Button';

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

const ButtonWrapper = styled('div')(({ theme }) => ({
  margin: theme.spacing(1),
  position: 'relative',
}));

type SubmitButtonProps = {
  isSaving: boolean;
  text?: string;
};

export function SubmitButton({ isSaving, text }: SubmitButtonProps) {
  return (
    <ButtonWrapper>
      <MuiButton
        type="submit"
        variant="contained"
        color="primary"
        disabled={isSaving}
      >
        {text || 'Save'}
      </MuiButton>
      {isSaving && (
        <CircularProgress
          size={24}
          sx={{
            color: green[500],
            position: 'absolute',
            top: '50%',
            left: '50%',
            marginTop: -12,
            marginLeft: -12,
          }}
        />
      )}
    </ButtonWrapper>
  );
}

SubmitButton.defaultProps = {
  text: 'Save',
};
