import React, { type ReactNode } from 'react';
import Icon from '@mui/material/Icon';
import IconButton from '../IconButton';
import type { RowActionType } from './types';
import { EntityObject } from '../../../../../apiConnector/interfaces/entity';

export type Props<E extends EntityObject> = {
  action: RowActionType<E>;
  data: E;
  size: 'small' | 'medium';
  setLoading?: (isLoading: boolean) => void;
};

function isF(x: unknown): x is Function {
  return typeof x === 'function';
}
function isS(x: unknown): x is string {
  return typeof x === 'string';
}

function CustomIcon({
  icon,
}: {
  icon: string | (() => ReactNode) | ReactNode;
}) {
  if (isF(icon)) {
    return icon();
  }
  if (isS(icon)) {
    return (
      <Icon
        className={icon}
        fontSize="inherit"
        sx={{
          width: '1.25em',
          height: '1.25em',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
        }}
      />
    );
  }
  return icon;
}

export default function RowAction<E extends EntityObject>({
  action,
  data,
  size,
  setLoading,
}: Props<E>) {
  if (typeof action === 'function') {
    return <>{action(data, size, setLoading)}</>;
  }
  const shown = isF(action.shown) ? action.shown(data) : action.shown;
  if (!shown) return null;
  const actionDisabled = action.disabled ?? false;
  const disabled = isF(actionDisabled) ? actionDisabled(data) : actionDisabled;
  const color = action.color ?? 'inherit';

  return (
    <IconButton
      size={action.size || size}
      color={color}
      disabled={disabled}
      onClick={(event) =>
        action.onClick ? action.onClick(event, data, setLoading) : undefined
      }
      title={action.tooltip}
    >
      <CustomIcon icon={action.icon} />
    </IconButton>
  );
}

RowAction.defaultProps = {
  setLoading: undefined,
};
