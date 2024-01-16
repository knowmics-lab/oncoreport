// noinspection SuspiciousTypeOfGuard

import React from 'react';
import { useNavigate, generatePath } from 'react-router-dom';
import RepositoryTable from '../components/ui/RepositoryTable';
import { PatientDiseaseEntity, PatientRepository } from '../../../api';
import { Gender, TypeOfNotification } from '../../../interfaces';
import { Alignment } from '../components/ui/Table/types';
import { runAsync } from '../components/utils';
import Routes from '../../../constants/routes.json';
import { ResultSet } from '../../../apiConnector';

export default function Patients() {
  const navigate = useNavigate();
  return (
    <RepositoryTable
      repositoryToken={PatientRepository}
      title="Patients"
      globalSearch
      columns={[
        {
          dataField: 'first_name',
          label: 'First Name',
        },
        {
          dataField: 'last_name',
          label: 'Last Name',
        },
        {
          dataField: 'gender',
          label: 'Gender',
          format: (v: Gender) => (v === Gender.m ? 'Male' : 'Female'),
        },
        {
          dataField: 'primary_disease',
          label: 'Disease',
          disableSorting: true,
          format: (v: PatientDiseaseEntity) => v.disease?.name,
        },
        'actions',
      ]}
      actions={[
        {
          shown: true,
          color: 'default',
          icon: 'fas fa-pencil-alt',
          tooltip: 'Edit',
          onClick: (_e, data) => {
            navigate(
              generatePath(Routes.PATIENTS_EDIT, {
                id: data.id,
              }),
            );
          },
        },
        {
          shown: true,
          color: 'default',
          icon: 'fas fa-fw fa-eye',
          tooltip: 'Clinical records',
          onClick: (_e, data) => {
            navigate(
              generatePath(Routes.PATIENT, {
                id: data.id,
              }),
            );
          },
        },
        {
          shown: true,
          color: 'default',
          icon: 'fas fa-tint',
          tooltip: 'Analysis',
          onClick: (_e, data) => {
            navigate(
              generatePath(Routes.JOBS_BY_PATIENT, {
                id: data.id,
              }),
            );
          },
        },
        {
          shown: true,
          color: 'secondary',
          icon: 'fas fa-trash',
          tooltip: 'Delete',
          onClick: (_e, data, setLoading) => {
            runAsync(async (manager) => {
              if (setLoading) setLoading(true);
              await data.delete();
              manager.pushSimple(
                'Patient deleted!',
                TypeOfNotification.success,
              );
              if (setLoading) setLoading(false);
            });
          },
        },
      ]}
      toolbar={[
        {
          align: Alignment.right,
          shown: true,
          icon: 'fas fa-plus',
          tooltip: 'Add',
          onClick: () => {
            navigate(generatePath(Routes.PATIENTS_CREATE));
          },
        },
        {
          align: Alignment.right,
          shown: true,
          icon: 'fas fa-redo',
          disabled: (s) => s.isLoading,
          tooltip: 'Refresh',
          onClick: (_e, _s, data) => {
            runAsync(async () => {
              if (data && data instanceof ResultSet) {
                await data.refresh();
              }
            });
          },
        },
      ]}
    />
  );
}
