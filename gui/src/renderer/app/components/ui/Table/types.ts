/* eslint-disable @typescript-eslint/no-explicit-any */
import type { MouseEvent, ReactNode } from 'react';
import { PropTypes } from '@mui/material';
import { EntityObject } from '../../../../../apiConnector/interfaces/entity';
import { Nullable } from '../../../../../apiConnector/interfaces/common';

export type ActionColumn = 'actions';

export type NormalColumn<E extends EntityObject> = {
  key?: string;
  dataField: keyof E;
  sortingField?: string;
  disableSorting?: boolean;
  label: string;
  minWidth?: number;
  align?: any; // TODO: PropTypes.Alignment;
  format?: (value: any, data: E) => ReactNode;
};

export type TableColumn<E extends EntityObject> =
  | ActionColumn
  | NormalColumn<E>;

export type TableState = {
  currentPage: Nullable<number>;
  rowsPerPage: Nullable<number>;
  totalRows: Nullable<number>;
  isLoading: boolean;
};

export type RowActionFunction<E extends EntityObject> = (
  data: E,
  size: 'small' | 'medium',
  setLoading?: (isLoading: boolean) => void,
) => Iterable<ReactNode> | ReactNode[] | ReactNode;

export type RowActionObject<E extends EntityObject> = {
  shown: boolean | ((data: E) => boolean);
  icon: string | (() => ReactNode) | ReactNode;
  size?: 'small' | 'medium';
  disabled?: boolean | ((data: E) => boolean);
  color?: PropTypes.Color;
  onClick?: (
    e: MouseEvent<HTMLButtonElement>,
    data: E,
    setLoading?: (isLoading: boolean) => void,
  ) => void;
  tooltip?: string;
};

export type RowActionType<E extends EntityObject> =
  | RowActionObject<E>
  | RowActionFunction<E>;

export enum Alignment {
  left = 'left',
  center = 'center',
  right = 'right',
}

export type ToolbarActionFunction<E extends EntityObject> = (
  state: TableState,
  data?: E[],
  setLoading?: (isLoading: boolean) => void,
) => Iterable<ReactNode> | ReactNode[] | ReactNode;

export type ToolbarActionCustom<E extends EntityObject> = {
  custom: true;
  action: ToolbarActionFunction<E>;
  align: Alignment;
};

export type ToolbarActionButton<E extends EntityObject> = {
  custom?: false;
  align: Alignment;
  shown: boolean | ((state: TableState, data?: E[]) => boolean);
  icon: string | (() => ReactNode);
  disabled?: boolean | ((state: TableState, data?: E[]) => boolean);
  color?: PropTypes.Color;
  onClick?: (
    e: MouseEvent,
    state: TableState,
    data?: E[],
    setLoading?: (isLoading: boolean) => void,
  ) => void;
  tooltip?: string;
};

export type ToolbarActionType<E extends EntityObject> =
  | ToolbarActionCustom<E>
  | ToolbarActionButton<E>;
