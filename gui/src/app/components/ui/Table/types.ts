/* eslint-disable @typescript-eslint/no-explicit-any */
import type { MouseEvent, ReactNode, ReactNodeArray } from 'react';
import { PropTypes } from '@material-ui/core';
import { EntityObject } from '../../../../apiConnector/interfaces/entity';
import { Nullable } from '../../../../apiConnector/interfaces/common';

export type ActionColumn = 'actions';

export type NormalColumn<E extends EntityObject> = {
  dataField: keyof E;
  sortingField?: keyof E;
  disableSorting?: boolean;
  label: string;
  minWidth?: number;
  align?: PropTypes.Alignment;
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
  size: 'small' | 'medium'
) => ReactNodeArray | ReactNode;

export type RowActionObject<E extends EntityObject> = {
  shown: boolean | ((data: E) => boolean);
  icon: string | (() => ReactNode);
  size?: 'small' | 'medium';
  disabled?: boolean | ((data: E) => boolean);
  color?: PropTypes.Color;
  onClick?: (e: MouseEvent<HTMLButtonElement>, data: E) => void;
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

export type ToolbarActionFunction = (
  state: TableState
) => ReactNodeArray | ReactNode;

export type ToolbarActionCustom = {
  custom: true;
  action: ToolbarActionFunction;
  align: Alignment;
};

export type ToolbarActionButton = {
  custom?: false;
  align: Alignment;
  shown: boolean | ((state: TableState) => boolean);
  icon: string | (() => ReactNode);
  disabled?: boolean | ((state: TableState) => boolean);
  color?: PropTypes.Color;
  onClick?: (e: MouseEvent, state: TableState) => void;
  tooltip?: string;
};

export type ToolbarActionType = ToolbarActionCustom | ToolbarActionButton;
