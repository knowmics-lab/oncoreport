import React, { useEffect, useState } from 'react';
import { InjectionToken } from 'tsyringe';
import type {
  RowActionType,
  TableColumn,
  ToolbarActionType,
} from './Table/types';
import { Collection, IdentifiableEntity } from '../../../interfaces';
import Repository from '../../../api/repositories/repository';
import Entity from '../../../api/entities/entity';
import { useService } from '../../../reactInjector';
import { runAsync } from '../utils';
import RemoteTable from './RemoteTable';

export type TableProps<
  D extends IdentifiableEntity,
  E extends Entity<D>,
  R extends Repository<D, E>
> = {
  title?: string | React.ReactNode | React.ReactNodeArray;
  size?: 'small' | 'medium';
  columns: TableColumn<D, E>[];
  toolbar?: ToolbarActionType[];
  actions?: RowActionType<D, E>[];
  sortable?: boolean;
  repositoryToken: InjectionToken<R>;
  onPageChange?: (page: number) => void;
};

export default function RepositoryTable<
  D extends IdentifiableEntity,
  E extends Entity<D>,
  R extends Repository<D, E>
>({
  title,
  size,
  columns,
  toolbar,
  actions,
  sortable,
  repositoryToken,
  onPageChange,
}: TableProps<D, E, R>) {
  const [data, setData] = useState<Collection<E> | undefined>(undefined);
  const [fetching, setFetching] = useState(false);
  const repository = useService(repositoryToken);

  useEffect(() => {
    const id = repository.subscribeRefresh((page) => {
      if (page && data && data.meta.current_page === page) {
        runAsync(async () => {
          setFetching(true);
          setData(await repository.fetchPage(page));
          setFetching(false);
        });
      } else {
        setData(undefined);
      }
    });
    return () => {
      repository.unsubscribeRefresh(id);
    };
  }, [repository, data]);

  const fetchPage = (page = 1) => {
    runAsync(
      async () => {
        setFetching(true);
        setData(await repository.fetchPage(page));
        setFetching(false);
      },
      () => setFetching(false)
    );
  };

  return (
    <RemoteTable
      title={title}
      size={size}
      columns={columns}
      toolbar={toolbar}
      actions={actions}
      sortable={sortable}
      onPageChange={onPageChange}
      fetching={fetching}
      data={data}
      requestPage={(page) => fetchPage(page)}
      changeRowsPerPage={(nRows) => {
        repository.itemsPerPage = nRows;
        fetchPage();
      }}
      changeSorting={(sorting) => {
        repository.sorting = sorting;
        fetchPage(data?.meta.current_page || 1);
      }}
    />
  );
}
