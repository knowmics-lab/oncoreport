// noinspection SuspiciousTypeOfGuard

import React from 'react';
import { generatePath } from 'react-router';
import { useHistory } from 'react-router-dom';
import RepositoryTable from '../ui/RepositoryTable';
import { PatientDiseaseEntity, PatientRepository } from '../../../api';
import { Gender, TypeOfNotification } from '../../../interfaces';
import { Alignment } from '../ui/Table/types';
import { runAsync } from '../utils';
import Routes from '../../../constants/routes.json';
import { ResultSet } from '../../../apiConnector';

export default function Patients() {
  const history = useHistory();
  return (
    <RepositoryTable
      repositoryToken={PatientRepository}
      title="Patients"
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
            history.push(
              generatePath(Routes.PATIENTS_EDIT, {
                id: data.id,
              })
            );
          },
        },
        {
          shown: true,
          color: 'default',
          icon: 'fas fa-fw fa-eye',
          tooltip: 'Clinical records',
          onClick: (_e, data) => {
            history.push(
              generatePath(Routes.PATIENT, {
                id: data.id,
              })
            );
          },
        },
        {
          shown: true,
          color: 'default',
          icon: 'fas fa-tint',
          tooltip: 'Analysis',
          onClick: (_e, data) => {
            history.push(
              generatePath(Routes.JOBS_BY_PATIENT, {
                id: data.id,
              })
            );
          },
        },
        {
          shown: true,
          color: 'secondary',
          icon: 'fas fa-trash',
          tooltip: 'Delete',
          onClick: (_e, data) => {
            runAsync(async (manager) => {
              await data.delete();
              manager.pushSimple(
                'Patient deleted!',
                TypeOfNotification.success
              );
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
            history.push(generatePath(Routes.PATIENTS_CREATE));
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
