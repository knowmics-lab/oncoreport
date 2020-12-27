import React from 'react';
import TableBody from '@material-ui/core/TableBody';
import TableRow from '@material-ui/core/TableRow';
import TableCell from '@material-ui/core/TableCell';
import type { TableColumn } from './types';
import { IdentifiableEntity } from '../../../../interfaces';
import Entity from '../../../../api/entities/entity';

type Props<D extends IdentifiableEntity, E extends Entity<D>> = {
  columns: TableColumn<D, E>[];
  hasCheckbox?: boolean;
};

export default function Body<
  D extends IdentifiableEntity,
  E extends Entity<D>
>({ columns, hasCheckbox }: Props<D, E>) {
  const numOfColumns = columns.length + (hasCheckbox ? 1 : 0);
  return (
    <TableBody>
      <TableRow>
        <TableCell colSpan={numOfColumns}>Loading...TODO</TableCell>
      </TableRow>
    </TableBody>
  );
}

Body.defaultProps = {
  hasCheckbox: false,
};
