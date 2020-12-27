import React, {
  useMemo,
  forwardRef,
  ForwardedRef,
  MouseEventHandler,
} from 'react';
import { Link as RouterLink } from 'react-router-dom';
import { Tooltip, IconButton as IB, PropTypes } from '@material-ui/core';
import { Nullable } from '../../../interfaces';

export type IconButtonType = {
  color?: PropTypes.Color;
  title?: string;
  children: React.ReactNode;
  disabled?: boolean;
  href?: Nullable<string>;
  size?: 'small' | 'medium';
  onClick?: MouseEventHandler<HTMLButtonElement>;
};

const makeTooltip = (
  component: React.ReactElement,
  tooltip: string,
  disabled: boolean
) => {
  if (!tooltip) return component;
  return disabled ? (
    <Tooltip title={tooltip}>
      <span>{component}</span>
    </Tooltip>
  ) : (
    <Tooltip title={tooltip}>{component}</Tooltip>
  );
};

export default function IconButton({
  color,
  title,
  children,
  disabled,
  href,
  size,
  onClick,
}: IconButtonType) {
  const renderLink = useMemo(
    () =>
      forwardRef((itemProps, ref: ForwardedRef<HTMLAnchorElement>) => (
        <RouterLink to={href || ''} {...itemProps} innerRef={ref} />
      )),
    [href]
  );
  if (!onClick && href) {
    return makeTooltip(
      <IB color={color} disabled={disabled} component={renderLink} size={size}>
        {children}
      </IB>,
      title || '',
      disabled || false
    );
  }
  const onClickFn = onClick || (() => undefined);
  return makeTooltip(
    <IB color={color} disabled={disabled} onClick={onClickFn} size={size}>
      {children}
    </IB>,
    title || '',
    disabled || false
  );
}

IconButton.defaultProps = {
  color: 'default',
  size: 'medium',
  disabled: false,
  title: '',
  href: null,
  onClick: null,
};
