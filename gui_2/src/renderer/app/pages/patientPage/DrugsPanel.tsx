/* eslint-disable react/no-unstable-nested-components */
import React, { useCallback, useRef, useState } from 'react';
import { Dayjs } from 'dayjs';
import Dialog from '@mui/material/Dialog';
import DialogTitle from '@mui/material/DialogTitle';
import { DialogContent } from '@mui/material';
import {
  DrugEntity,
  PatientDiseaseEntity,
  PatientDrugRepository,
  PatientEntity,
} from '../../../../api';
import TabPanel from './TabPanel';
import GoBackRow from './GoBackRow';
import RepositoryTable, {
  RepositoryTableRef,
} from '../../components/ui/RepositoryTable';
import { Alignment } from '../../components/ui/Table/types';
import { runAsync } from '../../components/utils';
import { TypeOfNotification } from '../../../../interfaces';
import PatientDrugForm from './forms/patientDrugForm';

interface PanelProps {
  index: number;
  currentTab: number;
  patient: PatientEntity;
}

export default function DrugsPanel({ currentTab, patient, index }: PanelProps) {
  const tableRef = useRef<RepositoryTableRef>();
  const { id } = patient;
  const [open, setOpen] = useState(false);
  const closeModal = useCallback(() => setOpen(false), [setOpen]);

  return (
    <TabPanel value={currentTab} index={index}>
      <RepositoryTable
        doNotWrap
        toolbar={[
          {
            align: Alignment.right,
            shown: true,
            icon: 'fas fa-plus',
            tooltip: 'Add Drug',
            onClick: () => {
              setOpen(true);
            },
          },
        ]}
        columns={[
          {
            dataField: 'drug',
            sortingField: 'drug_id',
            label: 'Drug',
            format: (v: DrugEntity) => v.name,
          },
          {
            dataField: 'disease',
            sortingField: 'patient_disease_id',
            label: 'Disease',
            format: (v?: PatientDiseaseEntity) =>
              v?.disease?.name ?? 'Not Specified',
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
            shown: true,
            color: 'secondary',
            icon: 'fas fa-trash',
            tooltip: 'Delete',
            onClick: (_e, data) => {
              runAsync(async (manager) => {
                await data.delete();
                manager.pushSimple('Drug deleted!', TypeOfNotification.success);
              });
            },
          },
        ]}
        repositoryToken={PatientDrugRepository}
        parameters={{ patient_id: id }}
        collapsible
        collapsibleContent={(row) => {
          return (
            <PatientDrugForm
              drug={row}
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
        <DialogTitle>Add Drug</DialogTitle>
        <DialogContent style={{ minWidth: 600 }}>
          {open && patient.drugs && (
            <PatientDrugForm
              drug={patient.drugs.new()}
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
  );
}
