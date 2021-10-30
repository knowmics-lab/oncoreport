import React from 'react';
import { Grid, Typography } from '@material-ui/core';
import { PatientEntity } from '../../../../api';
import TabPanel from './TabPanel';
import GoBackRow from './GoBackRow';

interface PatientPanelsProps {
  index: number;
  currentTab: number;
  patient: PatientEntity;
}

export default function PatientDataPanel({
  index,
  currentTab,
  patient,
}: PatientPanelsProps) {
  return (
    <TabPanel value={currentTab} index={index}>
      <Grid container spacing={2}>
        <Grid item sm>
          <Typography variant="overline" display="block" gutterBottom>
            Code: {patient.code}
          </Typography>
        </Grid>
      </Grid>
      <Grid container spacing={2}>
        <Grid item sm>
          <Typography variant="overline" display="block" gutterBottom>
            Name: {patient.first_name}
          </Typography>
        </Grid>
        <Grid item sm>
          <Typography variant="overline" display="block" gutterBottom>
            Surname: {patient.last_name}
          </Typography>
        </Grid>
      </Grid>
      <Grid container spacing={2}>
        <Grid item sm>
          <Typography variant="overline" display="block" gutterBottom>
            Age: {patient.age}
          </Typography>
        </Grid>
        <Grid item sm>
          <Typography variant="overline" display="block" gutterBottom>
            Gender: {patient.gender}
          </Typography>
        </Grid>
      </Grid>
      <Grid container spacing={2}>
        <Grid item sm>
          <Typography variant="overline" display="block" gutterBottom>
            Email: {patient.email}
          </Typography>
        </Grid>
        <Grid item sm>
          <Typography variant="overline" display="block" gutterBottom>
            Fiscal Number: {patient.fiscalNumber}
          </Typography>
        </Grid>
      </Grid>
      <Grid container spacing={2}>
        <Grid item sm>
          <Typography variant="overline" display="block" gutterBottom>
            Current disease: {patient.primary_disease?.disease?.name}
          </Typography>
        </Grid>
      </Grid>
      <GoBackRow id={patient.id} />
    </TabPanel>
  );
}
