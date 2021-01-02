/* eslint-disable @typescript-eslint/no-explicit-any */
import type { MouseEvent, ReactNode, ReactNodeArray } from 'react';
import { PropTypes } from '@material-ui/core';
import type { IdentifiableEntity, Nullable } from '../../../../interfaces';
import Entity from '../../../../api/entities/entity';

export type ActionColumn = 'actions';

export type NormalColumn<D extends IdentifiableEntity, E extends Entity<D>> = {
  dataField: keyof E;
  sortingField?: keyof E;
  disableSorting?: boolean;
  label: string;
  minWidth?: number;
  align?: PropTypes.Alignment;
  format?: (value: any, data: E) => ReactNode;
};

export type TableColumn<D extends IdentifiableEntity, E extends Entity<D>> =
  | ActionColumn
  | NormalColumn<D, E>;

export type TableState = {
  currentPage: Nullable<number>;
  rowsPerPage: Nullable<number>;
  totalRows: Nullable<number>;
  isLoading: boolean;
};

export type RowActionFunction<
  D extends IdentifiableEntity,
  E extends Entity<D>
> = (data: E, size: 'small' | 'medium') => ReactNodeArray | ReactNode;

export type RowActionObject<
  D extends IdentifiableEntity,
  E extends Entity<D>
> = {
  shown: boolean | ((data: E) => boolean);
  icon: string | (() => ReactNode);
  size?: 'small' | 'medium';
  disabled?: boolean | ((data: E) => boolean);
  color?: PropTypes.Color;
  onClick?: (e: MouseEvent<HTMLButtonElement>, data: E) => void;
  tooltip?: string;
};

export type RowActionType<D extends IdentifiableEntity, E extends Entity<D>> =
  | RowActionObject<D, E>
  | RowActionFunction<D, E>;

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
