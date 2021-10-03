/* eslint-disable @typescript-eslint/no-explicit-any */
import React, { useCallback, useMemo, useState } from 'react';
import { useHistory, useParams } from 'react-router-dom';
import { createStyles, makeStyles } from '@material-ui/core/styles';
import { green } from '@material-ui/core/colors';
import {
  Box,
  Grid,
  Icon,
  Paper,
  Typography,
  Accordion,
  AccordionDetails,
  AccordionSummary,
  Dialog,
  DialogActions,
  DialogContent,
  DialogContentText,
  DialogTitle,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  useTheme,
} from '@material-ui/core';
import SwipeableViews from 'react-swipeable-views';
import { generatePath } from 'react-router';
import AppBar from '@material-ui/core/AppBar';
import Tabs from '@material-ui/core/Tabs';
import Tab from '@material-ui/core/Tab';
import ExpandMoreIcon from '@material-ui/icons/ExpandMore';
import { Field, Form, Formik } from 'formik';
import {
  PatientEntity,
  PatientRepository,
  ReasonRepository,
  ResourceEntity,
} from '../../../api';
import { useService } from '../../../reactInjector';
import Routes from '../../../constants/routes.json';
import TumorList from './tumorList';
import Button, { SubmitButton } from '../ui/Button';
import { JobsByPatientPage } from '.';
import { FormikSelect } from '../ui/Form/FormikSelect';
import TextField from '../ui/Form/TextField';
import Connector from '../../../api/adapters/connector';
import LoadingSection from '../ui/LoadingSection';
import useRepositoryFetch from '../../hooks/useRepositoryFetch';
import useRepositoryFetchOne from '../../hooks/useRepositoryFetchOne';

const useStyles = makeStyles((theme) =>
  createStyles({
    paper: {
      padding: 0,
      borderRadius: 10,
    },
    appbar: {
      borderTopLeftRadius: 10,
      borderTopRightRadius: 10,
    },
    formControl: {
      margin: theme.spacing(1),
      minWidth: 120,
    },
    buttonWrapper: {
      margin: theme.spacing(1),
      position: 'relative',
    },
    buttonProgress: {
      color: green[500],
      position: 'absolute',
      top: '50%',
      left: '50%',
      marginTop: -12,
      marginLeft: -12,
    },
    backdrop: {
      zIndex: theme.zIndex.drawer + 1,
      color: '#fff',
    },
    topSeparation: {
      marginTop: theme.spacing(2),
    },
    bottomSeparation: {
      marginBottom: theme.spacing(2),
    },
    stickyStyle: {
      backgroundColor: theme.palette.background.default,
    },
  })
);

interface TabPanelProps {
  children?: React.ReactNode;
  index: number;
  value: number;
}

function TabPanel({ children, value, index, ...other }: TabPanelProps) {
  return (
    <div
      role="tabpanel"
      hidden={value !== index}
      id={`simple-tabpanel-${index}`}
      aria-labelledby={`simple-tab-${index}`}
      {...other}
    >
      {value === index && <Box p={3}>{children}</Box>}
    </div>
  );
}

TabPanel.defaultProps = {
  children: undefined,
};

type DrugData = undefined | { drug: any; index: number };
interface ReasonDialogProps {
  onSubmit: (
    patientId: number,
    drugId: number,
    reasons: number[],
    comment: string,
    setSubmitting: (state: boolean) => void
  ) => void;
  patient: PatientEntity;
  drugData: DrugData;
  setDrugData: (data: DrugData) => void;
  availableReasons: ResourceEntity[];
}

function ReasonDialog({
  onSubmit,
  patient,
  drugData,
  setDrugData,
  availableReasons,
}: ReasonDialogProps) {
  const [submitting, setSubmitting] = useState<boolean>(false);
  const onClose = useCallback(() => setDrugData(undefined), [setDrugData]);
  const otherReasons = useMemo(
    () =>
      availableReasons
        .filter((r) => r.name.toLowerCase().startsWith('other'))
        .map((r) => r.id),
    [availableReasons]
  );
  return (
    <Dialog open={!!drugData} onClose={onClose}>
      <DialogTitle>Suspension reasons for {drugData?.drug.name}</DialogTitle>
      <Formik<{ reasons: number[]; comment: string }>
        initialValues={{ reasons: [], comment: '' }}
        onSubmit={(d) => {
          onSubmit(
            patient.id ?? 0,
            drugData?.drug.id,
            d.reasons,
            d.comment,
            setSubmitting
          );
          onClose();
        }}
      >
        {({ values: { reasons } }) => {
          const hasOthers = otherReasons.some((i) => reasons.includes(i));
          return (
            <Form>
              <DialogContent>
                <DialogContentText>
                  Select one or more reasons
                </DialogContentText>
                <Field
                  name="reasons"
                  isMulti
                  component={FormikSelect}
                  options={availableReasons.map((r) => ({
                    value: r.id,
                    label: r.name,
                  }))}
                />
                {hasOthers && (
                  <TextField
                    label="Why are you suspending this drug?"
                    name="comment"
                  />
                )}
              </DialogContent>
              <DialogActions>
                <Button onClick={onClose} color="primary">
                  Cancel
                </Button>
                <SubmitButton text="Suspend" isSaving={submitting} />
              </DialogActions>
            </Form>
          );
        }}
      </Formik>
    </Dialog>
  );
}

// eslint-disable-next-line react/no-unused-prop-types
const GoBackRow = (props: { id: number }) => {
  const classes = useStyles();
  const history = useHistory();
  const backUrl = useMemo(() => generatePath(Routes.PATIENTS), []);
  return (
    <Grid
      container
      justifyContent="space-between"
      className={classes.topSeparation}
    >
      <Grid item xs="auto">
        <Button variant="contained" color="default" href={backUrl}>
          <Icon className="fas fa-arrow-left" /> Go Back
        </Button>
      </Grid>
      <Grid item xs="auto">
        <Button
          color="primary"
          variant="contained"
          onClick={() => {
            history.push(generatePath(Routes.PATIENTS_EDIT, props));
          }}
        >
          Edit
        </Button>
      </Grid>
    </Grid>
  );
};

interface PatientPanelsProps {
  currentTab: number;
  patient: PatientEntity;
}

const PatientDataPanel = ({ currentTab, patient }: PatientPanelsProps) => {
  return (
    <TabPanel value={currentTab} index={0}>
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
            Current disease: {patient.disease.name}
          </Typography>
        </Grid>
      </Grid>
      <GoBackRow id={patient.id ?? 0} />
    </TabPanel>
  );
};

const PreviousDiseasesPanel = ({ currentTab, patient }: PatientPanelsProps) => {
  const [expanded, setExpanded] = React.useState<number>(-1);
  const classes = useStyles();
  return (
    <TabPanel value={currentTab} index={1}>
      {patient.diseases.length === 0 && (
        <Typography variant="overline" display="block" gutterBottom>
          Nothing to show here.
        </Typography>
      )}
      {patient.diseases.map((disease: any) => (
        <Accordion
          key={`accordion-${disease.id}`}
          TransitionProps={{ unmountOnExit: true }}
          expanded={expanded === disease.id}
          onChange={(_e, isExpanded: boolean) => {
            setExpanded(isExpanded ? disease.id : -1);
          }}
        >
          <AccordionSummary expandIcon={<ExpandMoreIcon />}>
            <Typography>{disease.name}</Typography>
          </AccordionSummary>
          <AccordionDetails>
            <TableContainer component={Paper}>
              <Table>
                <TableHead>
                  <TableRow className={classes.stickyStyle}>
                    <TableCell>Drugs</TableCell>
                  </TableRow>
                </TableHead>
                <TableBody>
                  {disease.medicines.map((medicine: any) => (
                    <TableRow
                      key={`accordion-${disease.id}-drug-${medicine.id}`}
                    >
                      <TableCell>{medicine.name}</TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            </TableContainer>
          </AccordionDetails>
        </Accordion>
      ))}
      <GoBackRow id={patient.id ?? 0} />
    </TabPanel>
  );
};

interface DrugsPanelProps extends PatientPanelsProps {
  availableReasons: ResourceEntity[];
  refreshPatient: () => void;
}

const PreviousTumorPanel = ({
  currentTab,
  patient,
  availableReasons,
  refreshPatient,
}: DrugsPanelProps) => {
  return (
    <TabPanel value={currentTab} index={2}>
      <Typography variant="h5" component="h3">
        Tumors list
      </Typography>
      <TumorList
        patient={patient}
        availableReasons={availableReasons}
        refreshPatient={refreshPatient}
      />
      <GoBackRow id={patient.id ?? 0} />
    </TabPanel>
  );
};

const DrugsPanel = ({
  currentTab,
  patient,
  availableReasons,
  refreshPatient,
}: DrugsPanelProps) => {
  const classes = useStyles();
  const connectorService = useService(Connector);
  const [stopDrug, setStopDrug] = React.useState<
    | undefined
    | {
        drug: any;
        index: number;
      }
  >();
  return (
    <TabPanel value={currentTab} index={3}>
      <TableContainer component={Paper}>
        <Table>
          <TableHead>
            <TableRow className={classes.stickyStyle}>
              <TableCell>Drugs</TableCell>
              <TableCell />
            </TableRow>
          </TableHead>
          <TableBody>
            {patient.drugs.length === 0 && (
              <TableRow>
                <TableCell colSpan={2}>No drugs found.</TableCell>
              </TableRow>
            )}
            {patient.drugs.map((drug: any, i: number) => (
              <TableRow key={`drugs-list-${drug.id}`}>
                <TableCell>{drug.name}</TableCell>
                <TableCell>
                  <Button
                    size="small"
                    variant="contained"
                    color="secondary"
                    disabled={!!drug.end_date}
                    onClick={async () => {
                      setStopDrug({ drug, index: i });
                    }}
                  >
                    {!!drug.end_date && 'Suspended'}
                    {!drug.end_date && 'Suspend'}
                  </Button>
                </TableCell>
              </TableRow>
            ))}
          </TableBody>
        </Table>
      </TableContainer>

      <ReasonDialog
        onSubmit={(patientId, drugId, reasons, comment, setSubmitting) => {
          setSubmitting(true);
          connectorService
            .callPost(`detach/${patientId}/${drugId}`, {
              reasons,
              comment,
            })
            .then(() => {
              setSubmitting(false);
              refreshPatient();
              return true;
            })
            .catch((e) => {
              console.log(e);
              setSubmitting(false);
            });
        }}
        patient={patient}
        drugData={stopDrug}
        setDrugData={setStopDrug}
        availableReasons={availableReasons}
      />
      <GoBackRow id={patient.id ?? 0} />
    </TabPanel>
  );
};

export default function Patient() {
  const classes = useStyles();
  const theme = useTheme();
  const { id } = useParams<{ id: string }>();
  const [currentTab, setCurrentTab] = useState<number>(0);

  const [loadingPatient, patient, refresh] = useRepositoryFetchOne(
    PatientRepository,
    +id
  );
  const [loadingReasons, reasons] = useRepositoryFetch(ReasonRepository);
  const loading = loadingPatient || loadingReasons;

  function a11yProps(index: number) {
    return {
      id: `simple-tab-${index}`,
      'aria-controls': `simple-tabpanel-${index}`,
    };
  }

  return (
    <LoadingSection loading={loading || !patient}>
      {patient && (
        <>
          <Typography
            variant="h5"
            component="h3"
            className={classes.bottomSeparation}
          >
            Clinical records of {patient.fullName}
          </Typography>
          <Paper elevation={1} className={classes.paper}>
            <AppBar
              position="static"
              color="default"
              className={classes.appbar}
            >
              <Tabs
                value={currentTab}
                onChange={(_e, newValue: number) => setCurrentTab(newValue)}
                aria-label="tabs"
                variant="fullWidth"
                textColor="primary"
                indicatorColor="primary"
              >
                <Tab label="Personal data" {...a11yProps(0)} />
                <Tab label="Previous diseases" {...a11yProps(1)} />
                <Tab label="Previous tumors" {...a11yProps(2)} />
                <Tab label="Drugs" {...a11yProps(3)} />
                <Tab label="Analysis" {...a11yProps(4)} />
              </Tabs>
            </AppBar>
            <SwipeableViews
              axis={theme.direction === 'rtl' ? 'x-reverse' : 'x'}
              index={currentTab}
              onChangeIndex={(idx: number) => setCurrentTab(idx)}
              style={{ padding: 10 }}
            >
              <PatientDataPanel currentTab={currentTab} patient={patient} />
              <PreviousDiseasesPanel
                currentTab={currentTab}
                patient={patient}
              />
              <PreviousTumorPanel
                availableReasons={reasons}
                refreshPatient={refresh}
                currentTab={currentTab}
                patient={patient}
              />
              <DrugsPanel
                currentTab={currentTab}
                patient={patient}
                availableReasons={reasons}
                refreshPatient={refresh}
              />
              <TabPanel value={currentTab} index={4}>
                <JobsByPatientPage />
              </TabPanel>
            </SwipeableViews>
          </Paper>
        </>
      )}
    </LoadingSection>
  );
}
