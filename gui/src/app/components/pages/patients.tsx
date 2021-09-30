import React, { useState } from 'react';
import { generatePath } from 'react-router';
import { useHistory } from 'react-router-dom';
import RepositoryTable from '../ui/RepositoryTable';
import { DiseaseEntity, PatientEntity, PatientRepository } from '../../../api';
import { Gender, PatientObject, TypeOfNotification } from '../../../interfaces';
import { Alignment } from '../ui/Table/types';
import { runAsync } from '../utils';
import { useService } from '../../../reactInjector';
import Routes from '../../../constants/routes.json';

export default function Patients() {
  const repository = useService(PatientRepository);
  const [currentPage, setCurrentPage] = useState(1);
  const history = useHistory();
  return (
    <RepositoryTable<PatientObject, PatientEntity, PatientRepository>
      title="Patients"
      onPageChange={(page) => setCurrentPage(page)}
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
          dataField: 'disease',
          label: 'Disease',
          disableSorting: true,
          format: (v: DiseaseEntity) => v.name,
        },
        'actions',
      ]}
      actions={[
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
          icon: 'fas fa-eye',
          tooltip: 'detail',
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
              await repository.refreshPage(currentPage);
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
          onClick: (_e, s) => {
            if (s.currentPage) {
              const page = s.currentPage;
              runAsync(async () => {
                await repository.refreshPage(page);
              });
            }
          },
        },
      ]}
      repositoryToken={PatientRepository}
    />
  );
}
