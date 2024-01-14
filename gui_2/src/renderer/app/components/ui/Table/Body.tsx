/* eslint-disable react/destructuring-assignment */
import React, { useCallback } from 'react';
import TableBody from '@mui/material/TableBody';
import TableRow from '@mui/material/TableRow';
import TableCell from '@mui/material/TableCell';
import Checkbox from '@mui/material/Checkbox';
import { Collapse, IconButton } from '@mui/material';
import KeyboardArrowUpIcon from '@mui/icons-material/KeyboardArrowUp';
import KeyboardArrowDownIcon from '@mui/icons-material/KeyboardArrowDown';
import type { RowActionType, TableColumn } from './types';
import RowActions from './RowActions';
import { EntityObject } from '../../../../../apiConnector/interfaces/entity';
import useToggle from '../../../hooks/useToggle';

function Cell<E extends EntityObject>(
  column: TableColumn<E>,
  row: E,
  keyBase: string,
  actions: RowActionType<E>[],
  size: 'small' | 'medium',
  setLoading?: (isLoading: boolean) => void,
) {
  if (column !== 'actions') {
    const value = row[column.dataField];
    return (
      <TableCell
        key={`${keyBase}-${column.key ?? column.dataField.toString()}`}
        align={column.align}
      >
        {column.format ? column.format(value, row) : `${value}`}
      </TableCell>
    );
  }
  return (
    <TableCell key={`${keyBase}-actions`} align="center">
      <RowActions
        actions={actions}
        data={row}
        size={size}
        setLoading={setLoading}
      />
    </TableCell>
  );
}

type EmptyRowProps<E extends EntityObject> = {
  columns: TableColumn<E>[];
  hasCheckbox?: boolean;
  collapsible?: boolean;
  collapsibleContent?: (row: E) => React.ReactNode;
};

function EmptyRow<E extends EntityObject>({
  columns,
  hasCheckbox,
  collapsible,
  collapsibleContent,
}: EmptyRowProps<E>) {
  const isCollapsible = collapsible && !!collapsibleContent;
  const numColumns =
    columns.length + (hasCheckbox ? 1 : 0) + (isCollapsible ? 1 : 0);
  return (
    <TableRow>
      <TableCell colSpan={numColumns} align="center">
        No records have been found.
      </TableCell>
    </TableRow>
  );
}

EmptyRow.defaultProps = {
  hasCheckbox: false,
  collapsible: false,
  collapsibleContent: undefined,
};

type RowProps<E extends EntityObject> = {
  row: E;
  columns: TableColumn<E>[];
  actions: RowActionType<E>[];
  size: 'small' | 'medium';
  hasCheckbox?: boolean;
  isSelected: (id: E['id']) => boolean;
  handleSelect?: (id: E['id']) => void;
  collapsible?: boolean;
  collapsibleContent?: (row: E) => React.ReactNode;
  setLoading?: (isLoading: boolean) => void;
};

function Row<E extends EntityObject>({
  row,
  columns,
  actions,
  size,
  hasCheckbox,
  isSelected,
  handleSelect,
  collapsible,
  collapsibleContent,
  setLoading,
}: RowProps<E>) {
  const { id } = row;
  const isCollapsible = collapsible && !!collapsibleContent;
  const numColumns =
    columns.length + (hasCheckbox ? 1 : 0) + (isCollapsible ? 1 : 0);
  const [open, toggleOpen] = useToggle(false);
  return (
    <>
      <TableRow
        hover
        sx={{
          '& > *': {
            borderBottom: 'unset',
          },
        }}
        role="checkbox"
        tabIndex={-1}
        selected={isSelected(id)}
        onClick={() => (handleSelect ? handleSelect(id) : undefined)}
      >
        {isCollapsible && (
          <TableCell>
            <IconButton
              aria-label="expand row"
              size="small"
              onClick={(e) => {
                e.preventDefault();
                e.stopPropagation();
                toggleOpen();
              }}
            >
              {open ? <KeyboardArrowUpIcon /> : <KeyboardArrowDownIcon />}
            </IconButton>
          </TableCell>
        )}
        {hasCheckbox && (
          <TableCell padding="checkbox">
            <Checkbox checked={isSelected(id)} />
          </TableCell>
        )}
        {columns.map((column) =>
          Cell(column, row, `row-${id}`, actions, size, setLoading),
        )}
      </TableRow>
      {isCollapsible && (
        <TableRow>
          <TableCell
            style={{ paddingBottom: 0, paddingTop: 0 }}
            colSpan={numColumns}
          >
            <Collapse in={open} timeout="auto" unmountOnExit>
              {collapsibleContent(row)}
            </Collapse>
          </TableCell>
        </TableRow>
      )}
    </>
  );
}

Row.defaultProps = {
  hasCheckbox: false,
  handleSelect: undefined,
  collapsible: false,
  collapsibleContent: undefined,
  setLoading: undefined,
};

type Props<E extends EntityObject> = {
  data: E[];
  columns: TableColumn<E>[];
  actions: RowActionType<E>[];
  size: 'small' | 'medium';
  hasCheckbox?: boolean;
  selectedItems?: E['id'][];
  handleSelect?: (id: E['id']) => void;
  collapsible?: boolean;
  collapsibleContent?: (row: E) => React.ReactNode;
  setLoading?: (loading: boolean) => void;
};

export default function Body<E extends EntityObject>({
  data,
  columns,
  actions,
  size,
  hasCheckbox,
  selectedItems,
  handleSelect,
  collapsible,
  collapsibleContent,
  setLoading,
}: Props<E>) {
  const isSelected = useCallback(
    (id: E['id']) =>
      hasCheckbox && selectedItems ? selectedItems.includes(id) : false,
    [hasCheckbox, selectedItems],
  );
  return (
    <TableBody>
      {data.length > 0 &&
        data.map((row) => (
          <Row
            key={`row-${row.id}`}
            isSelected={isSelected}
            actions={actions}
            row={row}
            size={size}
            columns={columns}
            hasCheckbox={hasCheckbox}
            handleSelect={handleSelect}
            collapsible={collapsible}
            collapsibleContent={collapsibleContent}
            setLoading={setLoading}
          />
        ))}
      {data.length === 0 && (
        <EmptyRow
          columns={columns}
          hasCheckbox={hasCheckbox}
          collapsible={collapsible}
          collapsibleContent={collapsibleContent}
        />
      )}
    </TableBody>
  );
}

Body.defaultProps = {
  hasCheckbox: false,
  selectedItems: [],
  handleSelect: undefined,
  collapsible: false,
  collapsibleContent: undefined,
  setLoading: undefined,
};
