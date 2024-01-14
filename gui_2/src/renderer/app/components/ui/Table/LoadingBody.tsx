import React from 'react';
import TableBody from '@mui/material/TableBody';
import TableRow from '@mui/material/TableRow';
import TableCell from '@mui/material/TableCell';
import type { TableColumn } from './types';
import { EntityObject } from '../../../../../apiConnector/interfaces/entity';

type Props<E extends EntityObject> = {
  columns: TableColumn<E>[];
  hasCheckbox?: boolean;
  collapsible?: boolean;
};

export default function Body<E extends EntityObject>({
  columns,
  hasCheckbox,
  collapsible,
}: Props<E>) {
  const numOfColumns =
    columns.length + (hasCheckbox ? 1 : 0) + (collapsible ? 1 : 0);
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
  collapsible: false,
};
