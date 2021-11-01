import React, { useCallback, useRef, useState } from 'react';
import { Dayjs } from 'dayjs';
import Dialog from '@material-ui/core/Dialog';
import DialogTitle from '@material-ui/core/DialogTitle';
import { DialogContent } from '@material-ui/core';
import {
  DiseaseEntity,
  PatientDiseaseRepository,
  PatientEntity,
} from '../../../../api';
import TabPanel from './TabPanel';
import GoBackRow from './GoBackRow';
import RepositoryTable, { RepositoryTableRef } from '../../ui/RepositoryTable';
import PatientDiseaseForm from './forms/patientDiseaseForm';
import { Alignment } from '../../ui/Table/types';
import { runAsync } from '../../utils';
import { TypeOfNotification } from '../../../../interfaces';

interface PanelProps {
  index: number;
  currentTab: number;
  patient: PatientEntity;
}

export default function DiseasesPanel({
  currentTab,
  patient,
  index,
}: PanelProps) {
  const tableRef = useRef<RepositoryTableRef>();
  const {
    id,
    primary_disease: { id: primaryDiseaseId },
  } = patient;
  const [open, setOpen] = useState(false);
  const closeModal = useCallback(() => setOpen(false), [setOpen]);
  return (
    <>
      <TabPanel value={currentTab} index={index}>
        <RepositoryTable
          doNotWrap
          toolbar={[
            {
              align: Alignment.right,
              shown: true,
              icon: 'fas fa-plus',
              tooltip: 'Add Disease',
              onClick: () => {
                setOpen(true);
              },
            },
          ]}
          columns={[
            {
              dataField: 'disease',
              sortingField: 'disease_id',
              label: 'Disease',
              format: (v: DiseaseEntity) => v.name,
            },
            {
              key: 'is-tumor',
              dataField: 'disease',
              disableSorting: true,
              label: 'Tumor',
              format: (v: DiseaseEntity) => (v.tumor ? 'Yes' : 'No'),
            },
            {
              dataField: 'start_date',
              label: 'Start',
              format: (v: Dayjs) => v.format('YYYY-MM-DD'),
            },
            {
              dataField: 'end_date',
              label: 'End',
              format: (v?: Dayjs) => v?.format('YYYY-MM-DD') ?? 'Current',
            },
            'actions',
          ]}
          actions={[
            {
              shown: (d) => d.id !== primaryDiseaseId,
              color: 'secondary',
              icon: 'fas fa-trash',
              tooltip: 'Delete',
              onClick: (_e, data) => {
                runAsync(async (manager) => {
                  await data.delete();
                  manager.pushSimple(
                    'Disease deleted!',
                    TypeOfNotification.success
                  );
                });
              },
            },
          ]}
          repositoryToken={PatientDiseaseRepository}
          parameters={{ patient_id: id }}
          collapsible
          collapsibleContent={(row) => {
            return (
              <PatientDiseaseForm
                disease={row}
                patient={patient}
                onSave={() => {
                  if (tableRef.current) tableRef.current.refresh();
                }}
              />
            );
          }}
          tableRef={tableRef}
        />
        <Dialog open={open} onClose={closeModal}>
          <DialogTitle>Add Disease</DialogTitle>
          <DialogContent style={{ minWidth: 600 }}>
            {open && patient.diseases && (
              <PatientDiseaseForm
                disease={patient.diseases.new()}
                patient={patient}
                onSave={() => {
                  closeModal();
                  if (tableRef.current) tableRef.current.refresh();
                }}
              />
            )}
          </DialogContent>
        </Dialog>
        <GoBackRow id={id} />
      </TabPanel>
    </>
  );
}
