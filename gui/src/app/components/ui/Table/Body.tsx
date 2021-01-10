import React from 'react';
import TableBody from '@material-ui/core/TableBody';
import TableRow from '@material-ui/core/TableRow';
import TableCell from '@material-ui/core/TableCell';
import Checkbox from '@material-ui/core/Checkbox';
import type { RowActionType, TableColumn } from './types';
import RowActions from './RowActions';
import { Collection, IdentifiableEntity } from '../../../../interfaces';
import Entity from '../../../../api/entities/entity';

function Cell<D extends IdentifiableEntity, E extends Entity<D>>(
  column: TableColumn<D, E>,
  row: E,
  keyBase: string,
  actions: RowActionType<D, E>[],
  size: 'small' | 'medium'
) {
  if (column !== 'actions') {
    const value = row[column.dataField];
    return (
      <TableCell key={`${keyBase}-${column.dataField}`} align={column.align}>
        {column.format ? column.format(value, row) : value}
      </TableCell>
    );
  }
  return (
    <TableCell key={`${keyBase}-actions`} align="center">
      <RowActions actions={actions} data={row} size={size} />
    </TableCell>
  );
}

type Props<D extends IdentifiableEntity, E extends Entity<D>> = {
  data: Collection<E>;
  columns: TableColumn<D, E>[];
  actions: RowActionType<D, E>[];
  size: 'small' | 'medium';
  hasCheckbox?: boolean;
  selectedItems?: D['id'][];
  handleSelect?: (id: D['id']) => void;
};

export default function Body<
  D extends IdentifiableEntity,
  E extends Entity<D>
>({
  data,
  columns,
  actions,
  size,
  hasCheckbox,
  selectedItems,
  handleSelect,
}: Props<D, E>) {
  const isSelected = (id: D['id']) =>
    hasCheckbox && selectedItems ? selectedItems.includes(id) : false;
  const { data: dataArray } = data;
  return (
    <TableBody>
      {dataArray.length > 0 &&
        dataArray.map((row) => {
          const { id } = row;
          return (
            <TableRow
              hover
              role="checkbox"
              tabIndex={-1}
              key={`row-${id}`}
              selected={isSelected(id)}
              onClick={() => (handleSelect ? handleSelect(id) : undefined)}
            >
              {hasCheckbox && (
                <TableCell padding="checkbox">
                  <Checkbox checked={isSelected(id)} />
                </TableCell>
              )}
              {columns.map((column) =>
                Cell(column, row, `row-${id}`, actions, size)
              )}
            </TableRow>
          );
        })}
    </TableBody>
  );
}

Body.defaultProps = {
  hasCheckbox: false,
  selectedItems: [],
  handleSelect: undefined,
};
