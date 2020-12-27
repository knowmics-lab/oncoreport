import React from 'react';
import Icon from '@material-ui/core/Icon';
import IconButton from '../IconButton';
import type { RowActionType } from './types';
import { IdentifiableEntity } from '../../../../interfaces';
import Entity from '../../../../api/entities/entity';

export type Props<D extends IdentifiableEntity, E extends Entity<D>> = {
  action: RowActionType<D, E>;
  data: E;
  size: 'small' | 'medium';
};

// eslint-disable-next-line @typescript-eslint/ban-types
function isF(x: unknown): x is Function {
  return typeof x === 'function';
}

export default function RowAction<
  D extends IdentifiableEntity,
  E extends Entity<D>
>({ action, data, size }: Props<D, E>) {
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
