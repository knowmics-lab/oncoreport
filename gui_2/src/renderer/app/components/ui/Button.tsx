import React, { useMemo, forwardRef, ForwardedRef } from 'react';
import { Link as RouterLink } from 'react-router-dom';
import { Button as OB, createStyles, PropTypes } from '@material-ui/core';
import CircularProgress from '@material-ui/core/CircularProgress';
import makeStyles from '@material-ui/core/styles/makeStyles';
import { green } from '@material-ui/core/colors';

type ButtonProps = {
  color?: PropTypes.Color;
  children: React.ReactNode;
  disabled?: boolean;
  href?: string;
  size?: 'small' | 'medium' | 'large';
  variant?: 'text' | 'outlined' | 'contained';
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
        <RouterLink to={href || ''} {...itemProps} innerRef={ref} />
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

const useStyles = makeStyles((theme) =>
  createStyles({
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
  }),
);

type SubmitButtonProps = {
  isSaving: boolean;
  text?: string;
};

export function SubmitButton({ isSaving, text }: SubmitButtonProps) {
  const classes = useStyles();
  return (
    <div className={classes.buttonWrapper}>
      <OB type="submit" variant="contained" color="primary" disabled={isSaving}>
        {text || 'Save'}
      </OB>
      {isSaving && (
        <CircularProgress size={24} className={classes.buttonProgress} />
      )}
    </div>
  );
}

SubmitButton.defaultProps = {
  text: 'Save',
};
