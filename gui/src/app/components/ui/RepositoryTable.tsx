import React, {
  MutableRefObject,
  useCallback,
  useEffect,
  useMemo,
  useState,
} from 'react';
import { InjectionToken } from 'tsyringe';
import type {
  RowActionType,
  TableColumn,
  ToolbarActionType,
} from './Table/types';
import { runAsync } from '../utils';
import RemoteTable from './RemoteTable';
import {
  EntityObject,
  QueryBuilderInterface,
} from '../../../apiConnector/interfaces/entity';
import { Repository, SortingDirection } from '../../../apiConnector';
import useRepositoryQuery, {
  QueryBuilderCallback,
} from '../../hooks/useRepositoryQuery';
import { SimpleMapType } from '../../../apiConnector/interfaces/common';

export type RepositoryTableRef = {
  refresh: () => void;
};

export interface TableProps<E extends EntityObject> {
  title?: string | React.ReactNode | React.ReactNodeArray;
  doNotWrap?: boolean;
  size?: 'small' | 'medium';
  columns: TableColumn<E>[];
  toolbar?: ToolbarActionType<E>[];
  actions?: RowActionType<E>[];
  sortable?: boolean;
  repositoryToken: InjectionToken<Repository<E>>;
  queryBuilderCallback?: QueryBuilderCallback<E>;
  parameters?: SimpleMapType;
  onPageChanged?: (page: number) => void;
  hasCheckbox?: boolean;
  selectedItems?: E['id'][];
  handleSelect?: (id: E['id']) => void;
  handleSelectAll?: () => void;
  collapsible?: boolean;
  collapsibleContent?: (row: E) => React.ReactNode;
  tableRef?: MutableRefObject<RepositoryTableRef | undefined>;
}

type SortingSpec = SimpleMapType<SortingDirection>;

export default function RepositoryTable<E extends EntityObject>({
  title,
  doNotWrap,
  size,
  columns,
  toolbar,
  actions,
  sortable,
  repositoryToken,
  queryBuilderCallback,
  parameters,
  onPageChanged,
  hasCheckbox,
  selectedItems,
  handleSelect,
  handleSelectAll,
  collapsible,
  collapsibleContent,
  tableRef,
}: TableProps<E>) {
  const [rowsPerPage, setRowsPerPage] = useState(15);
  const [sorting, setSorting] = useState<SortingSpec>({});

  const callbackMemoized = useMemo(() => {
    return (builder: QueryBuilderInterface<E>) => {
      let finalBuilder = builder;
      if (queryBuilderCallback) finalBuilder = queryBuilderCallback(builder);
      return finalBuilder.orderByAll(sorting).paginate(rowsPerPage);
    };
  }, [queryBuilderCallback, rowsPerPage, sorting]);

  const [loading, data, forceRefresh] = useRepositoryQuery(
    repositoryToken,
    callbackMemoized,
    parameters
  );

  useEffect(() => {
    if (tableRef) {
      tableRef.current = {
        refresh: forceRefresh,
      };
    }
    return () => {
      if (tableRef) {
        tableRef.current = undefined;
      }
    };
  }, [tableRef, forceRefresh]);

  const onChangeRowsPerPage = useCallback(
    (nRows: number) => {
      setRowsPerPage(nRows);
      forceRefresh();
    },
    [setRowsPerPage, forceRefresh]
  );

  const onChangeSorting = useCallback(
    (newSorting: SortingSpec) => {
      setSorting(newSorting);
      forceRefresh();
    },
    [setSorting, forceRefresh]
  );

  return (
    <RemoteTable
      title={title}
      doNotWrap={doNotWrap}
      size={size}
      columns={columns}
      toolbar={toolbar}
      actions={actions}
      sortable={sortable}
      onPageChanged={onPageChanged}
      fetching={loading}
      currentPage={data?.currentPage}
      rowsPerPage={data?.perPage}
      sorting={data?.query?.sort}
      totalRows={data?.total}
      data={data}
      onPageRequest={(page) => runAsync(async () => data?.goToPage(page))}
      onChangeRowsPerPage={onChangeRowsPerPage}
      onChangeSorting={onChangeSorting}
      hasCheckbox={hasCheckbox}
      selectedItems={selectedItems}
      handleSelect={handleSelect}
      handleSelectAll={handleSelectAll}
      collapsible={collapsible}
      collapsibleContent={collapsibleContent}
    />
  );
}
