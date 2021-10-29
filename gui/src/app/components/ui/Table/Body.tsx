import React from 'react';
import TableBody from '@material-ui/core/TableBody';
import TableRow from '@material-ui/core/TableRow';
import TableCell from '@material-ui/core/TableCell';
import Checkbox from '@material-ui/core/Checkbox';
import type { RowActionType, TableColumn } from './types';
import RowActions from './RowActions';
import { EntityObject } from '../../../../apiConnector/interfaces/entity';

function Cell<E extends EntityObject>(
  column: TableColumn<E>,
  row: E,
  keyBase: string,
  actions: RowActionType<E>[],
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

type Props<E extends EntityObject> = {
  data: E[];
  columns: TableColumn<E>[];
  actions: RowActionType<E>[];
  size: 'small' | 'medium';
  hasCheckbox?: boolean;
  selectedItems?: E['id'][];
  handleSelect?: (id: E['id']) => void;
};

export default function Body<E extends EntityObject>({
  data,
  columns,
  actions,
  size,
  hasCheckbox,
  selectedItems,
  handleSelect,
}: Props<E>) {
  const isSelected = (id: E['id']) =>
    hasCheckbox && selectedItems ? selectedItems.includes(id) : false;
  return (
    <TableBody>
      {data.length > 0 &&
        data.map((row) => {
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
