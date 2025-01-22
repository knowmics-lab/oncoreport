/* eslint-disable no-nested-ternary */
import React from 'react';
import { has, get } from 'lodash';
import TableHead from '@mui/material/TableHead';
import TableRow from '@mui/material/TableRow';
import TableSortLabel from '@mui/material/TableSortLabel';
import TableCell from '@mui/material/TableCell';
import Checkbox from '@mui/material/Checkbox';
import { Theme } from '@mui/material';
import type { NormalColumn, TableColumn } from './types';
import { EntityObject } from '../../../../../apiConnector/interfaces/entity';
import { SimpleMapType } from '../../../../../apiConnector/interfaces/common';
import { SortingDirection } from '../../../../../apiConnector';
import { Utils } from '../../../../../api';

const stickyStyle = (theme: Theme) => ({
  backgroundColor: theme.palette.background.default,
});

type SortingSpec = SimpleMapType<SortingDirection>;

type Props<E extends EntityObject> = {
  columns: TableColumn<E>[];
  sorting: SortingSpec;
  sortable: boolean;
  changeSorting: (s: SortingSpec) => void;
  hasCheckbox?: boolean;
  single?: boolean;
  selectedAny?: boolean;
  selectedAll?: boolean;
  handleSelect?: () => void;
  collapsible?: boolean;
};

export default function Header<E extends EntityObject>({
  columns,
  sorting,
  sortable,
  changeSorting,
  hasCheckbox,
  single,
  selectedAny,
  selectedAll,
  handleSelect,
  collapsible,
}: Props<E>) {
  const sf = (column: NormalColumn<E>): keyof E =>
    (column.sortingField || column.dataField) as unknown as keyof E;
  const makeChangeHandler =
    (column: keyof E) =>
    (event: React.MouseEvent<HTMLSpanElement, MouseEvent>) => {
      const oldDirection = get(sorting, column, null);
      const newDirection =
        oldDirection === null ? 'desc' : oldDirection === 'desc' ? 'asc' : null;
      const newSorting =
        newDirection === null
          ? Utils.filterByKey(sorting, (k) => k !== column)
          : { ...sorting, [column]: newDirection };
      changeSorting(newSorting);
      event.preventDefault();
    };
  return (
    <TableHead>
      <TableRow>
        {collapsible && <TableCell />}
        {hasCheckbox && (
          <TableCell padding="checkbox">
            {!single && (
              <Checkbox
                indeterminate={selectedAny}
                checked={selectedAll}
                onChange={handleSelect}
              />
            )}
          </TableCell>
        )}
        {columns.map((column) =>
          column !== 'actions' ? (
            <TableCell
              key={column.key ?? column.dataField.toString()}
              align={column.align}
              style={{ minWidth: column.minWidth }}
              sx={stickyStyle}
            >
              {sortable && !column.disableSorting ? (
                <TableSortLabel
                  active={has(sorting, sf(column))}
                  direction={get(sorting, sf(column), undefined)}
                  onClick={makeChangeHandler(sf(column))}
                >
                  {column.label}
                </TableSortLabel>
              ) : (
                column.label
              )}
            </TableCell>
          ) : (
            <TableCell
              key="actions"
              align="center"
              sx={stickyStyle}
            >
              Actions
            </TableCell>
          ),
        )}
      </TableRow>
    </TableHead>
  );
}

Header.defaultProps = {
  hasCheckbox: false,
  selectedAny: false,
  selectedAll: false,
  handleSelect: undefined,
  single: true,
  collapsible: false,
};
