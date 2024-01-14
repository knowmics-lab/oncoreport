/* eslint-disable react/no-unstable-nested-components */
import React, { useMemo, forwardRef, ForwardedRef } from 'react';
import { Link as RouterLink } from 'react-router-dom';
import { Button as OB, styled } from '@mui/material';
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

export default function Button({
  color: co,
  children: c,
  disabled: d,
  href,
  size: s,
  variant: v,
  onClick,
}: ButtonProps) {
  const renderLink = useMemo(
    () =>
      forwardRef((itemProps, ref: ForwardedRef<HTMLAnchorElement>) => (
        <RouterLink to={href || ''} {...itemProps} ref={ref} />
      )),
    [href],
  );
  if (onClick) {
    return (
      <OB variant={v} color={co} disabled={d} onClick={onClick} size={s}>
        {c}
      </OB>
    );
  }
  return (
    <OB variant={v} color={co} disabled={d} size={s} component={renderLink}>
      {c}
    </OB>
  );
}

Button.defaultProps = {
  color: 'default',
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
      <OB type="submit" variant="contained" color="primary" disabled={isSaving}>
        {text || 'Save'}
      </OB>
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
