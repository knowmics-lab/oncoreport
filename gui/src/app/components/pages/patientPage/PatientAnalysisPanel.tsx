import React from 'react';
import { PatientEntity } from '../../../../api';
import TabPanel from './TabPanel';
import GoBackRow from './GoBackRow';
import JobsTableByPatient from '../tables/jobsTableByPatient';

interface PanelProps {
  index: number;
  currentTab: number;
  patient: PatientEntity;
}

export default function PatientAnalysisPanel({
  currentTab,
  patient,
  index,
}: PanelProps) {
  const { id } = patient;
  return (
    <TabPanel value={currentTab} index={index}>
      <JobsTableByPatient patient={patient} doNotWrap />
      <GoBackRow id={id} />
    </TabPanel>
  );
}
