import React, { useState } from 'react';
import { useParams } from 'react-router-dom';
import { Paper, Typography } from '@mui/material';
import AppBar from '@mui/material/AppBar';
import Tabs from '@mui/material/Tabs';
import Tab from '@mui/material/Tab';
import { PatientRepository } from '../../../api';
import LoadingSection from '../components/ui/LoadingSection';
import useRepositoryFetchOne from '../hooks/useRepositoryFetchOne';
import PatientDataPanel from './patientPage/PatientDataPanel';
import DiseasesPanel from './patientPage/DiseasesPanel';
import DrugsPanel from './patientPage/DrugsPanel';
import PatientAnalysisPanel from './patientPage/PatientAnalysisPanel';
import styles from './patientPage/useStyles';

export default function Patient() {
  const { id } = useParams<{ id: string }>();
  const [currentTab, setCurrentTab] = useState<number>(0);
  const [loadingPatient, patient] = useRepositoryFetchOne(
    PatientRepository,
    +id!,
  );

  function a11yProps(index: number) {
    return {
      id: `simple-tab-${index}`,
      'aria-controls': `simple-tabpanel-${index}`,
    };
  }

  return (
    <LoadingSection loading={loadingPatient || !patient}>
      {!loadingPatient && patient && (
        <>
          <Typography variant="h5" component="h3" sx={styles.bottomSeparation}>
            Clinical records of {patient.fullName}
          </Typography>
          <Paper elevation={1} sx={styles.paper}>
            <AppBar position="static" color="default" sx={styles.appbar}>
              <Tabs
                value={currentTab}
                onChange={(_e, newValue: number) => setCurrentTab(newValue)}
                aria-label="tabs"
                variant="fullWidth"
                textColor="primary"
                indicatorColor="primary"
              >
                <Tab label="Personal data" {...a11yProps(0)} />
                <Tab label="Diseases" {...a11yProps(1)} />
                <Tab label="Drugs" {...a11yProps(3)} />
                <Tab label="Analysis" {...a11yProps(4)} />
              </Tabs>
            </AppBar>
            {/* <SwipeableViews */}
            {/*   axis={theme.direction === 'rtl' ? 'x-reverse' : 'x'} */}
            {/*   index={currentTab} */}
            {/*   onChangeIndex={(idx: number) => setCurrentTab(idx)} */}
            {/*   style={{ padding: 10 }} */}
            {/* > */}
            <PatientDataPanel
              currentTab={currentTab}
              patient={patient}
              index={0}
            />
            <DiseasesPanel
              currentTab={currentTab}
              patient={patient}
              index={1}
            />
            <DrugsPanel currentTab={currentTab} patient={patient} index={2} />
            <PatientAnalysisPanel
              currentTab={currentTab}
              patient={patient}
              index={3}
            />
            {/* </SwipeableViews> */}
          </Paper>
        </>
      )}
    </LoadingSection>
  );
}
