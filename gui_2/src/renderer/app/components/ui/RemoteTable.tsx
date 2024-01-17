import React, { useCallback, useEffect, useState } from 'react';
import Table from '@mui/material/Table';
import TablePagination from '@mui/material/TablePagination';
import TableContainer from '@mui/material/TableContainer';
import LinearProgress from '@mui/material/LinearProgress';
import { Typography, styled } from '@mui/material';
import type {
  RowActionType,
  TableColumn,
  ToolbarActionType,
} from './Table/types';
import TableHeader from './Table/Header';
import TableBody from './Table/Body';
import TableBodyLoading from './Table/LoadingBody';
import TableToolbar from './Table/Toolbar';
import { EntityObject } from '../../../../apiConnector/interfaces/entity';
import { SimpleMapType } from '../../../../apiConnector/interfaces/common';
import { SortingDirection } from '../../../../apiConnector';
import StandardContainer from './StandardContainer';

const Loading = styled('div')(({ theme }) => ({
  width: '100%',
  '& > * + *': {
    marginTop: theme.spacing(2),
  },
}));

type ContainerProps = React.PropsWithChildren<{
  wrapped: boolean;
}>;

function WrappedTableContainer({ children, wrapped }: ContainerProps) {
  if (!wrapped) return children;
  return <StandardContainer sx={{ px: 2 }}>{children}</StandardContainer>;
}

type SortingSpec = SimpleMapType<SortingDirection>;

export interface TableProps<E extends EntityObject> {
  title?:
    | string
    | React.ReactNode
    | React.ReactNode[]
    | Iterable<React.ReactNode>;
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
  globalSearch?: boolean;
  onGlobalSearch?: (value: string) => void;
}

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
  globalSearch,
  onGlobalSearch,
}: TableProps<E>) {
  const single = !!hasCheckbox && !handleSelectAll;
  const selectedAny = !single && selectedItems && selectedItems.length > 0;
  const selectedAll = !single && selectedItems?.length === totalRows;
  const isGlobalSearchEnabled = !!(globalSearch && onGlobalSearch);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    if (!data && !fetching) onPageRequest(1);
  }, [data, fetching, onPageRequest]);

  useEffect(() => {
    if (currentPage && onPageChanged) onPageChanged(currentPage);
  }, [currentPage, onPageChanged]);

  const handleChangePage = useCallback(
    (_event: React.MouseEvent<HTMLButtonElement> | null, newPage: number) =>
      onPageRequest(newPage + 1),
    [onPageRequest],
  );

  const handleChangeRowsPerPage = useCallback(
    (event: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement>) =>
      onChangeRowsPerPage(+event.target.value),
    [onChangeRowsPerPage],
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
      <TableContainer>
        <TableToolbar
          actions={finalToolbar}
          state={{ currentPage, rowsPerPage, totalRows, isLoading }}
          data={data}
          globalSearch={isGlobalSearchEnabled}
          onSearch={isGlobalSearchEnabled ? onGlobalSearch : undefined}
          setLoading={setLoading}
        />
        {(loading || isLoading) && (
          <Loading>
            <LinearProgress />
          </Loading>
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
              setLoading={setLoading}
            />
          )}
        </Table>
      </TableContainer>
      <TablePagination
        rowsPerPageOptions={[1, 15, 30, 50, 100]}
        component="div"
        count={totalRows ?? 0}
        rowsPerPage={rowsPerPage ?? 15}
        page={Math.max((currentPage ?? 1) - 1, 0)}
        onPageChange={handleChangePage}
        onRowsPerPageChange={handleChangeRowsPerPage}
      />
    </WrappedTableContainer>
  );
}

RemoteTable.defaultProps = {
  title: null,
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
  globalSearch: false,
  onGlobalSearch: undefined,
  doNotWrap: false,
  onPageChanged: undefined,
  currentPage: 0,
  rowsPerPage: 15,
  totalRows: undefined,
  sorting: undefined,
  data: undefined,
  fetching: undefined,
};
