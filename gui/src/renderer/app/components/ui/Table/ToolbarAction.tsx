import React from 'react';
import Icon from '@mui/material/Icon';
import IconButton from '../IconButton';
import type { TableState, ToolbarActionType } from './types';
import { EntityObject } from '../../../../../apiConnector/interfaces/entity';

export type Props<E extends EntityObject> = {
  action: ToolbarActionType<E>;
  state: TableState;
  data: E[] | undefined;
  setLoading?: (loading: boolean) => void;
};

function isF(x: unknown): x is Function {
  return typeof x === 'function';
}

export default function ToolbarAction<E extends EntityObject>({
  action,
  state,
  data,
  setLoading = undefined,
}: Props<E>) {
  if (action.custom) {
    if (action.action && isF(action.action)) {
      return <>{action.action(state, data, setLoading)}</>;
    }
    return null;
  }
  const shown = isF(action.shown) ? action.shown(state, data) : action.shown;
  if (!shown) return null;
  const actionDisabled = action.disabled || false;
  const disabled = isF(actionDisabled)
    ? actionDisabled(state, data)
    : actionDisabled;
  const icon = isF(action.icon) ? (
    action.icon()
  ) : (
    <Icon className={action.icon} fontSize="inherit" />
  );
  const color = action.color || 'inherit';
  return (
    <IconButton
      color={color}
      disabled={disabled}
      onClick={(event) =>
        action.onClick
          ? action.onClick(event, state, data, setLoading)
          : undefined
      }
      title={action.tooltip}
    >
      {icon}
    </IconButton>
  );
}

ToolbarAction.defaultProps = {
  setLoading: undefined,
};
