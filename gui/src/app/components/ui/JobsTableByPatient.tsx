import React from 'react';
import { JobEntity, JobRepository, PatientEntity } from '../../../api';
import RepositoryTable, {
  TableProps as RepositoryTableProps,
} from './RepositoryTable';

export type TableProps = Omit<
  RepositoryTableProps<JobEntity>,
  'repositoryToken'
> & {
  patient: PatientEntity | number;
};

export default function JobsTableByPatient({
  patient,
  parameters,
  ...props
}: TableProps) {
  return (
    <RepositoryTable
      {...props}
      repositoryToken={JobRepository}
      parameters={{
        ...(parameters ?? {}),
        patient: typeof patient === 'number' ? patient : patient.id,
      }}
    />
  );
}
