import React, { useMemo, useState } from 'react';
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

export interface TableProps<E extends EntityObject> {
  title?: string | React.ReactNode | React.ReactNodeArray;
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
}

type SortingSpec = SimpleMapType<SortingDirection>;

export default function RepositoryTable<E extends EntityObject>({
  title,
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

  const [loading, data, refresh] = useRepositoryQuery(
    repositoryToken,
    callbackMemoized,
    parameters
  );

  return (
    <RemoteTable
      title={title}
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
      onChangeRowsPerPage={(nRows) => {
        setRowsPerPage(nRows);
        refresh();
      }}
      onChangeSorting={setSorting}
      hasCheckbox={hasCheckbox}
      selectedItems={selectedItems}
      handleSelect={handleSelect}
      handleSelectAll={handleSelectAll}
      collapsible={collapsible}
      collapsibleContent={collapsibleContent}
    />
  );
}
