import React, { useCallback, useEffect } from 'react';
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
import { EntityObject } from '../../../apiConnector/interfaces/entity';
import { SimpleMapType } from '../../../apiConnector/interfaces/common';
import { SortingDirection } from '../../../apiConnector';

type ContainerProps = React.PropsWithChildren<{
  wrapped: boolean;
}>;

function WrappedTableContainer({ children, wrapped }: ContainerProps) {
  const classes = useStyles();
  if (!wrapped) return <>{children}</>;
  return (
    <Paper elevation={1} className={classes.root}>
      {children}
    </Paper>
  );
}

type SortingSpec = SimpleMapType<SortingDirection>;

export interface TableProps<E extends EntityObject> {
  title?: string | React.ReactNode | React.ReactNodeArray;
  doNotWrap?: boolean;
  size?: 'small' | 'medium';
  columns: TableColumn<E>[];
  toolbar?: ToolbarActionType<E>[];
  actions?: RowActionType<E>[];
  sortable?: boolean;
  onPageChanged?: (page: number) => void;
  onPageRequest: (page: number) => void;
  onChangeRowsPerPage: (nRows: number) => void;
  onChangeSorting: (sorting: SortingSpec) => void;
  currentPage?: number;
  rowsPerPage?: number;
  totalRows?: number;
  sorting?: SortingSpec;
  data?: E[];
  fetching?: boolean;
  hasCheckbox?: boolean;
  selectedItems?: E['id'][];
  handleSelect?: (id: E['id']) => void;
  handleSelectAll?: () => void;
  collapsible?: boolean;
  collapsibleContent?: (row: E) => React.ReactNode;
}

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

export default function RemoteTable<E extends EntityObject>({
  title,
  doNotWrap,
  size,
  columns,
  toolbar,
  actions,
  sortable,
  onPageChanged,
  onPageRequest,
  onChangeRowsPerPage,
  onChangeSorting,
  currentPage,
  rowsPerPage,
  totalRows,
  sorting,
  data,
  fetching,
  hasCheckbox,
  selectedItems,
  handleSelect,
  handleSelectAll,
  collapsible,
  collapsibleContent,
}: TableProps<E>) {
  const classes = useStyles();
  const single = !!hasCheckbox && !handleSelectAll;
  const selectedAny = !single && selectedItems && selectedItems.length > 0;
  const selectedAll = !single && selectedItems?.length === totalRows;

  useEffect(() => {
    if (!data && !fetching) onPageRequest(1);
  }, [data, fetching, onPageRequest]);

  useEffect(() => {
    if (currentPage && onPageChanged) onPageChanged(currentPage);
  }, [currentPage, onPageChanged]);

  const handleChangePage = useCallback(
    (_event: React.MouseEvent<HTMLButtonElement> | null, newPage: number) =>
      onPageRequest(newPage + 1),
    [onPageRequest]
  );

  const handleChangeRowsPerPage = useCallback(
    (event: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement>) =>
      onChangeRowsPerPage(+event.target.value),
    [onChangeRowsPerPage]
  );

  const finalSize = size || 'small';
  const finalActions = actions || [];
  const finalToolbar = toolbar || [];
  const finalSortable = sortable || true;
  const isLoading = fetching || !data;

  return (
    <WrappedTableContainer wrapped={!doNotWrap}>
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
          data={data}
        />
        {isLoading && (
          <div className={classes.loading}>
            <LinearProgress />
          </div>
        )}
        <Table stickyHeader size={size}>
          <TableHeader
            columns={columns}
            sorting={sorting ?? {}}
            sortable={finalSortable}
            changeSorting={onChangeSorting}
            hasCheckbox={hasCheckbox}
            single={single}
            handleSelect={handleSelectAll}
            selectedAll={selectedAll}
            selectedAny={selectedAny}
            collapsible={!!collapsible && !!collapsibleContent}
          />
          {(isLoading || !data) && (
            <TableBodyLoading
              columns={columns}
              hasCheckbox={hasCheckbox}
              collapsible={!!collapsible && !!collapsibleContent}
            />
          )}
          {!isLoading && !!data && (
            <TableBody
              data={data}
              columns={columns}
              actions={finalActions}
              size={finalSize}
              hasCheckbox={hasCheckbox}
              handleSelect={handleSelect}
              selectedItems={selectedItems}
              collapsible={collapsible}
              collapsibleContent={collapsibleContent}
            />
          )}
        </Table>
      </TableContainer>
      <TablePagination
        rowsPerPageOptions={[1, 15, 30, 50, 100]}
        component="div"
        count={totalRows ?? 0}
        rowsPerPage={rowsPerPage ?? 15}
        page={(currentPage ?? 1) - 1}
        onPageChange={handleChangePage}
        onRowsPerPageChange={handleChangeRowsPerPage}
      />
    </WrappedTableContainer>
  );
}

RemoteTable.defaultProps = {
  title: null,
  keyField: 'id',
  size: 'small',
  sortable: true,
  toolbar: [],
  actions: [],
  hasCheckbox: false,
  selectedItems: [],
  handleSelect: undefined,
  handleSelectAll: undefined,
  collapsible: false,
  collapsibleContent: undefined,
};
