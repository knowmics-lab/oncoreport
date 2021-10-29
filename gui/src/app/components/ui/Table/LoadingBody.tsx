import React from 'react';
import TableBody from '@material-ui/core/TableBody';
import TableRow from '@material-ui/core/TableRow';
import TableCell from '@material-ui/core/TableCell';
import type { TableColumn } from './types';
import { EntityObject } from '../../../../apiConnector/interfaces/entity';

type Props<E extends EntityObject> = {
  columns: TableColumn<E>[];
  hasCheckbox?: boolean;
};

export default function Body<E extends EntityObject>({
  columns,
  hasCheckbox,
}: Props<E>) {
  const numOfColumns = columns.length + (hasCheckbox ? 1 : 0);
  return (
    <TableBody>
      <TableRow>
        <TableCell colSpan={numOfColumns} align="center">
          Loading...
        </TableCell>
      </TableRow>
    </TableBody>
  );
}

Body.defaultProps = {
  hasCheckbox: false,
};
