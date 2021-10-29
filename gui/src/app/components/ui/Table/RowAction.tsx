import React from 'react';
import Icon from '@material-ui/core/Icon';
import IconButton from '../IconButton';
import type { RowActionType } from './types';
import { EntityObject } from '../../../../apiConnector/interfaces/entity';

export type Props<E extends EntityObject> = {
  action: RowActionType<E>;
  data: E;
  size: 'small' | 'medium';
};

// eslint-disable-next-line @typescript-eslint/ban-types
function isF(x: unknown): x is Function {
  return typeof x === 'function';
}

export default function RowAction<E extends EntityObject>({
  action,
  data,
  size,
}: Props<E>) {
  if (typeof action === 'function') {
    return <>{action(data, size)}</>;
  }
  const shown = isF(action.shown) ? action.shown(data) : action.shown;
  if (!shown) return null;
  const actionDisabled = action.disabled || false;
  const disabled = isF(actionDisabled) ? actionDisabled(data) : actionDisabled;
  const icon = isF(action.icon) ? (
    action.icon()
  ) : (
    <Icon className={action.icon} fontSize="inherit" />
  );
  const color = action.color || 'inherit';

  return (
    <IconButton
      size={action.size || size}
      color={color}
      disabled={disabled}
      onClick={(event) =>
        action.onClick ? action.onClick(event, data) : undefined
      }
      title={action.tooltip}
    >
      {icon}
    </IconButton>
  );
}
