/* eslint-disable no-nested-ternary */
import React from 'react';
import { has, get } from 'lodash';
import { createStyles, makeStyles } from '@material-ui/core/styles';
import TableHead from '@material-ui/core/TableHead';
import TableRow from '@material-ui/core/TableRow';
import TableSortLabel from '@material-ui/core/TableSortLabel';
import TableCell from '@material-ui/core/TableCell';
import Checkbox from '@material-ui/core/Checkbox';
import type { NormalColumn, TableColumn } from './types';
import { IdentifiableEntity, SortingSpec } from '../../../../interfaces';
import { Utils } from '../../../../api';
import Entity from '../../../../api/entities/entity';

const useStyles = makeStyles((theme) =>
  createStyles({
    stickyStyle: {
      backgroundColor: theme.palette.background.default,
    },
  })
);

type Props<D extends IdentifiableEntity, E extends Entity<D>> = {
  columns: TableColumn<D, E>[];
  sorting: SortingSpec;
  sortable: boolean;
  changeSorting: (s: SortingSpec) => void;
  hasCheckbox?: boolean;
  single?: boolean;
  selectedAny?: boolean;
  selectedAll?: boolean;
  handleSelect?: () => void;
};

export default function Header<
  D extends IdentifiableEntity,
  E extends Entity<D>
>({
  columns,
  sorting,
  sortable,
  changeSorting,
  hasCheckbox,
  single,
  selectedAny,
  selectedAll,
  handleSelect,
}: Props<D, E>) {
  const classes = useStyles();
  const sf = (column: NormalColumn<D, E>): keyof E =>
    column.sortingField || column.dataField;
  const makeChangeHandler = (column: keyof E) => (
    event: React.MouseEvent<HTMLSpanElement, MouseEvent>
  ) => {
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
              key={column.dataField as string}
              align={column.align}
              style={{ minWidth: column.minWidth }}
              className={classes.stickyStyle}
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
              className={classes.stickyStyle}
            >
              Actions
            </TableCell>
          )
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
};
