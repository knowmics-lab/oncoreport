import React, { useEffect } from 'react';
import Paper from '@material-ui/core/Paper';
import Table from '@material-ui/core/Table';
import TablePagination from '@material-ui/core/TablePagination';
import TableContainer from '@material-ui/core/TableContainer';
import LinearProgress from '@material-ui/core/LinearProgress';
import { makeStyles, Theme, createStyles, Typography } from '@material-ui/core';
import type {
  RowActionType,
  TableColumn,
  ToolbarActionType,
} from './Table/types';
import TableHeader from './Table/Header';
import TableBody from './Table/Body';
import TableBodyLoading from './Table/LoadingBody';
import TableToolbar from './Table/Toolbar';
import {
  Collection,
  IdentifiableEntity,
  SortingSpec,
} from '../../../interfaces';
import Entity from '../../../api/entities/entity';

export type TableProps<D extends IdentifiableEntity, E extends Entity<D>> = {
  title?: string | React.ReactNode | React.ReactNodeArray;
  size?: 'small' | 'medium';
  columns: TableColumn<D, E>[];
  toolbar?: ToolbarActionType[];
  actions?: RowActionType<D, E>[];
  sortable?: boolean;
  onPageChange?: (page: number) => void;
  requestPage: (page: number) => void;
  changeRowsPerPage: (nRows: number) => void;
  changeSorting: (sorting: SortingSpec) => void;
  data?: Collection<E>;
  fetching?: boolean;
};

const useStyles = makeStyles((theme: Theme) =>
  createStyles({
    root: {
      padding: 16,
    },
    container: {
      // maxHeight: 440
    },
    stickyStyle: {
      backgroundColor: theme.palette.background.default,
    },
    loading: {
      width: '100%',
      '& > * + *': {
        marginTop: theme.spacing(2),
      },
    },
  })
);

export default function RemoteTable<
  D extends IdentifiableEntity,
  E extends Entity<D>
>({
  title,
  size,
  columns,
  toolbar,
  actions,
  sortable,
  onPageChange,
  requestPage,
  changeRowsPerPage,
  changeSorting,
  data,
  fetching,
}: TableProps<D, E>) {
  const classes = useStyles();
  const currentPage = data?.meta.current_page;

  useEffect(() => {
    if (!data && !fetching) requestPage(1);
  }, [data, fetching, requestPage]);

  useEffect(() => {
    if (currentPage && onPageChange) onPageChange(currentPage);
  }, [currentPage, onPageChange]);

  const handleChangePage = (
    _event: React.MouseEvent<HTMLButtonElement> | null,
    newPage: number
  ) => requestPage(newPage + 1);

  const handleChangeRowsPerPage = (
    event: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement>
  ) => changeRowsPerPage(+event.target.value);

  const finalSize = size || 'small';
  const finalActions = actions || [];
  const finalToolbar = toolbar || [];
  const finalSortable = sortable || true;
  const rowsPerPage = data?.meta.per_page;
  const totalRows = data?.meta.total;
  const sorting = data?.meta.sorting || {};
  const isLoading = fetching || !data;

  return (
    <Paper elevation={1} className={classes.root}>
      {!!title &&
        (typeof title === 'string' ? (
          <Typography variant="h5" component="h3">
            {title}
          </Typography>
        ) : (
          title
        ))}
      <TableContainer className={classes.container}>
        <TableToolbar
          actions={finalToolbar}
          state={{ currentPage, rowsPerPage, totalRows, isLoading }}
        />
        {isLoading && (
          <div className={classes.loading}>
            <LinearProgress />
          </div>
        )}
        <Table stickyHeader size={size}>
          <TableHeader
            columns={columns}
            sorting={sorting}
            sortable={finalSortable}
            changeSorting={changeSorting}
          />
          {(isLoading || !data) && <TableBodyLoading columns={columns} />}
          {!isLoading && !!data && (
            <TableBody
              data={data}
              columns={columns}
              actions={finalActions}
              size={finalSize}
            />
          )}
        </Table>
      </TableContainer>
      <TablePagination
        rowsPerPageOptions={[1, 15, 30, 50, 100]}
        component="div"
        count={totalRows || 0}
        rowsPerPage={rowsPerPage || 15}
        page={(currentPage || 1) - 1}
        onChangePage={handleChangePage}
        onChangeRowsPerPage={handleChangeRowsPerPage}
      />
    </Paper>
  );
}

RemoteTable.defaultProps = {
  title: null,
  keyField: 'id',
  size: 'small',
  sortable: true,
  toolbar: [],
  actions: [],
};
