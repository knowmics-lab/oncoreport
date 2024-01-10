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
import useForceRerender from '../../hooks/useForceRerender';

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
  autoRefresh?: boolean;
  autoRefreshWhen?: (data: E[]) => boolean;
  autoRefreshTime?: number;
  globalSearch?: boolean;
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
  autoRefresh,
  autoRefreshWhen,
  autoRefreshTime = 30000,
  globalSearch = false,
}: TableProps<E>) {
  const [rowsPerPage, setRowsPerPage] = useState(15);
  const [sorting, setSorting] = useState<SortingSpec>({});
  const [search, setSearch] = useState<string>('');
  const [, forceRender] = useForceRerender();

  const callbackMemoized = useMemo(() => {
    return (builder: QueryBuilderInterface<E>) => {
      let finalBuilder = builder;
      if (queryBuilderCallback) finalBuilder = queryBuilderCallback(builder);
      if (search && search.trim().length > 0) {
        finalBuilder.search(search);
      }
      return finalBuilder.orderByAll(sorting).paginate(rowsPerPage);
    };
  }, [queryBuilderCallback, rowsPerPage, search, sorting]);

  const [loading, data, forceRefresh] = useRepositoryQuery(
    repositoryToken,
    callbackMemoized,
    parameters,
  );

  const isRefreshNeeded = useCallback(() => {
    if (autoRefresh && autoRefreshWhen) {
      return !!data && autoRefreshWhen(data ?? []);
    }
    return false;
  }, [autoRefresh, autoRefreshWhen, data]);

  useEffect(() => {
    if (!data) return () => {};
    const observer = {
      refreshed: () => forceRender(),
    };
    data.observe(observer);
    return () => data.removeObserver(observer);
  }, [data, forceRefresh, forceRender]);

  useEffect(() => {
    if (autoRefresh) {
      const timer = setInterval(() => {
        if (isRefreshNeeded()) {
          data?.refresh?.();
        }
      }, autoRefreshTime);
      return () => timer && clearInterval(timer);
    }
    return () => {};
  }, [autoRefresh, autoRefreshTime, data, forceRefresh, isRefreshNeeded]);

  useEffect(() => {
    if (tableRef) {
      tableRef.current = {
        refresh: () => data?.refresh?.(),
      };
    }
    return () => {
      if (tableRef) {
        tableRef.current = undefined;
      }
    };
  }, [tableRef, forceRefresh, data]);

  const onChangeRowsPerPage = useCallback(
    (nRows: number) => {
      setRowsPerPage(nRows);
      forceRefresh();
    },
    [setRowsPerPage, forceRefresh],
  );

  const onChangeSorting = useCallback(
    (newSorting: SortingSpec) => {
      setSorting(newSorting);
      forceRefresh();
    },
    [setSorting, forceRefresh],
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
      globalSearch={globalSearch}
      onGlobalSearch={(v) => {
        setSearch(v);
        forceRefresh();
      }}
    />
  );
}
