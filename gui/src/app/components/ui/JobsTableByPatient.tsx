import React, { useEffect, useState } from 'react';
import type {
  RowActionType,
  TableColumn,
  ToolbarActionType,
} from './Table/types';
import { Collection, JobObject } from '../../../interfaces';
import { useService } from '../../../reactInjector';
import { runAsync } from '../utils';
import RemoteTable from './RemoteTable';
import { JobEntity, JobRepository, PatientEntity } from '../../../api';

export type TableProps = {
  patient: PatientEntity;
  title?: string | React.ReactNode | React.ReactNodeArray;
  size?: 'small' | 'medium';
  columns: TableColumn<JobObject, JobEntity>[];
  toolbar?: ToolbarActionType[];
  actions?: RowActionType<JobObject, JobEntity>[];
  sortable?: boolean;
  onPageChange?: (page: number) => void;
};

export default function JobsTableByPatient({
  patient,
  title,
  size,
  columns,
  toolbar,
  actions,
  sortable,
  onPageChange,
}: TableProps) {
  const [data, setData] = useState<Collection<JobEntity> | undefined>(
    undefined
  );
  const [fetching, setFetching] = useState(false);
  const repository = useService(JobRepository);

  useEffect(() => {
    const id = repository.subscribeRefreshByPatient(patient, (_p, page) => {
      if (page && data && data.meta.current_page === page) {
        runAsync(async () => {
          setFetching(true);
          setData(await repository.fetchPageByPatient(patient, page));
          setFetching(false);
        });
      } else {
        setData(undefined);
      }
    });
    return () => {
      repository.unsubscribeRefreshByPatient(patient, id);
    };
  }, [repository, data, patient]);

  const fetchPage = (page = 1) => {
    runAsync(
      async () => {
        setFetching(true);
        setData(await repository.fetchPageByPatient(patient, page));
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
      onPageChanged={onPageChange}
      fetching={fetching}
      data={data}
      onPageRequest={(page) => fetchPage(page)}
      onChangeRowsPerPage={(nRows) => {
        repository.itemsPerPage = nRows;
        fetchPage();
      }}
      onChangeSorting={(sorting) => {
        repository.sorting = sorting;
        fetchPage(data?.meta.current_page || 1);
      }}
    />
  );
}
