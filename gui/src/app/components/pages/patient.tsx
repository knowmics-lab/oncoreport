import React, { useEffect, useState } from 'react';
import { useHistory, useParams } from 'react-router-dom';
import { createStyles, makeStyles } from '@material-ui/core/styles';
import { green } from '@material-ui/core/colors';

import {
  Box,
  CircularProgress,
  Grid,
  Icon,
  Paper,
  Typography,
} from '@material-ui/core';
import { generatePath } from 'react-router';
import {
  PatientEntity,
  PatientRepository,
  ReasonRepository,
  ResourceEntity,
} from '../../../api';
import { runAsync } from '../utils';
import { useService } from '../../../reactInjector';
import Routes from '../../../constants/routes.json';


const useStyles = makeStyles((theme) =>
  createStyles({
    paper: {
      padding: 16,
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
  })
);

import AppBar from '@material-ui/core/AppBar';
import Tabs from '@material-ui/core/Tabs';
import Tab from '@material-ui/core/Tab';
import { TumorList } from './tumorList';

import {
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
} from '@material-ui/core';
import ExpandMoreIcon from '@material-ui/icons/ExpandMore';
import Button, { SubmitButton } from '../ui/Button';
import { JobsByPatientPage } from '.';
import { Field, Form, Formik } from 'formik';
import { FormikSelect } from '../ui/Form/FormikSelect';
import TextField from '../ui/Form/TextField';
import Connector from '../../../api/adapters/connector';


type MaybePatient = PatientEntity | undefined;

export default function PatientForm(props: { id: number }) {
  const classes = useStyles();
  const repository = useService(PatientRepository);
  const [loading, setLoading] = useState(false);
  const [patient, setPatient] = useState<MaybePatient>();
  const [submitting, setSubmitting] = useState(false);
  const history = useHistory();
  const { id } = useParams<{ id?: string }>();
  const [value, setValue] = useState<number>(0);
  const [expanded, setExpanded] = React.useState<number | false>(false);
  const [stopDrug, setStopDrug] = React.useState<any>(false);

  const testDiv = (
    <div style={{ display: 'none' }}>Questo div è solo un test</div>
  );
  const reasonsRepository = useService(ReasonRepository);
  const [reasons, setReasons] = useState<ResourceEntity[] | undefined>();
  const connector: Connector = useService(Connector);

  function loadPatient() {
    runAsync(async () => {
      setLoading(true);
      if (id) {
        let p = await (await repository.fetch(+id)).refresh();
        setPatient(p);
        //setDrugs(p.drugs);
        console.log(JSON.stringify(props));
      } else {
        setPatient(repository.new());
      }
      setLoading(false);
    });
  }

  useEffect(() => {
    runAsync(async () => {
      loadPatient();
    });
  }, [id, repository]);



  useEffect(() => {
    runAsync(async () => {
      if (!reasons) {
        setLoading(true);
        const tmp = await reasonsRepository.fetchPage();
        // In realtà questo non serve.
        let t = tmp.data.reduce<ResourceEntity[]>((map, d) => {
          map.push(d);
          return map;
        }, []);
        setReasons(t);
        setLoading(false);
      }
    });
  }, [reasons, ReasonRepository]);

  interface TabPanelProps {
    children?: React.ReactNode;
    index: any;
    value: any;
  }

  function TabPanel(props: TabPanelProps) {
    const { children, value, index, ...other } = props;

    return (
      <div
        role="tabpanel"
        hidden={value !== index}
        id={`simple-tabpanel-${index}`}
        aria-labelledby={`simple-tab-${index}`}
        {...other}
      >
        {value === index && (
          <Box p={3}>
            {children}
          </Box>
        )}
      </div>
    );
  }


  function reasonDialog(onSubmit: Function) {
    const dRef:React.RefObject<any> = React.createRef();
    return (
      <Dialog
        open={stopDrug}
        onClose={() => {
          setStopDrug(false);
        }}
        aria-labelledby="form-dialog-title"
      >
        <DialogTitle id="form-dialog-title">
          Perchè interrompere {stopDrug ? stopDrug.drug.name : ''} ?
        </DialogTitle>
        <Formik
          initialValues={{ ragioni: [], comment: '' }}
          onSubmit={(d) =>{
            onSubmit(patient?.id, stopDrug.drug.id, d.ragioni, d.comment);
            setStopDrug(false);
          }}
        >
          <Form>
            <DialogContent>
              <DialogContentText>
                Puoi selezionare una o più ragioni.
              </DialogContentText>
              <Field
                name={'ragioni'}
                isMulti
                component={FormikSelect}
                options={(reasons ?? []).map((r) => {
                  return { value: r.id, label: r.name };
                })}
                label="perchè"
                onChangeCallback={(options: any) => {

                  dRef.current.style.display =
                    options.filter((option: any) => {
                      return option.label == 'other';
                    }).length > 0
                      ? 'block'
                      : 'none';
                }}
              />
              <div ref={dRef} style={{ display: 'none' }}>
                <TextField
                  label="Spiegaci perchè interrompere"
                  name="comment"
                />
              </div>
            </DialogContent>
            <DialogActions>
              <Button
                onClick={() => {
                  setStopDrug(false);
                }}
                color="primary"
              >
                Cancel
              </Button>
              <SubmitButton text="Save" isSaving={submitting} />
            </DialogActions>
          </Form>
        </Formik>
      </Dialog>
    );
  }


  const backUrl = generatePath(Routes.PATIENTS);

  return (
    <Paper
      elevation={1}
      className={classes.paper}
      style={{ padding: 0, borderRadius: 10 }}
    >
      {typeof id === typeof undefined || loading || !patient ? (
        <>
          <Grid container justify="center">
            <Grid item xs="auto">
              <CircularProgress color="inherit" />
            </Grid>
          </Grid>
          <Grid container justify="center">
            <Grid item xs="auto">
              Please wait...
            </Grid>
          </Grid>
        </>
      ) : (
        <>
          {testDiv}

          <AppBar
            position="static"
            style={{ borderTopLeftRadius: 10, borderTopRightRadius: 10 }}
          >
            <Tabs
              value={value}
              onChange={(_event: React.ChangeEvent<{}>, newValue: number) => {
                setValue(newValue);
              }}
              aria-label="tabs"
            >
              <Tab label="Anagrafica" />
              <Tab label="Patologie pregresse" />
              <Tab label="Tumori attuali" />
              <Tab label="Drugs" />
              <Tab label="Analyses" />
            </Tabs>
          </AppBar>
          <div style={{ padding: 10 }}>
            <Typography variant="h5" component="h3">
              Cartella clinica di {patient.fullName}
            </Typography>
            <TabPanel value={value} index={0}>
              <Grid container spacing={2}>
                <Typography variant="overline" display="block" gutterBottom>
                  Patient code: {patient.code}
                </Typography>
              </Grid>
              <Grid container spacing={2}>
                <Grid item sm>
                  <Typography variant="overline" display="block" gutterBottom>
                    Patient name: {patient.first_name}
                  </Typography>
                </Grid>
                <Grid item sm>
                  <Typography variant="overline" display="block" gutterBottom>
                    Patient surname: {patient.last_name}
                  </Typography>
                </Grid>
              </Grid>
              <Grid container spacing={2}>
                <Grid item sm>
                  <Typography variant="overline" display="block" gutterBottom>
                    Patient age: {patient.age}
                  </Typography>
                </Grid>
                <Grid item sm>
                  <Typography variant="overline" display="block" gutterBottom>
                    Patient gender: {patient.gender}
                  </Typography>
                </Grid>
              </Grid>
              <Grid container spacing={2}>
                <Grid item sm>
                  <Typography variant="overline" display="block" gutterBottom>
                    Patient email: {patient.email}
                  </Typography>
                </Grid>
                <Grid item sm>
                  <Typography variant="overline" display="block" gutterBottom>
                    Patient fiscal number: {patient.fiscalNumber}
                  </Typography>
                </Grid>
              </Grid>
              <Grid container spacing={2}>
                <Grid item sm>
                  <Typography variant="overline" display="block" gutterBottom>
                    Patient desease: {patient.disease.name}
                  </Typography>
                </Grid>
              </Grid>
            </TabPanel>

            {/** Pathologies */}
            <TabPanel value={value} index={1}>
              {patient.diseases.map((disease: any) => (
                <Accordion
                  TransitionProps={{ unmountOnExit: true }}
                  expanded={expanded == disease.id}
                  onChange={(
                    _event: React.ChangeEvent<{}>,
                    isExpanded: boolean
                  ) => {
                    setExpanded(isExpanded ? disease.id : false);
                  }}
                >
                  <AccordionSummary
                    expandIcon={<ExpandMoreIcon />}
                    aria-controls="panel1a-content"
                    id="panel1a-header"
                  >
                    <Typography>{disease.name}</Typography>
                  </AccordionSummary>
                  <AccordionDetails>
                    <TableContainer component={Paper}>
                      <Table>
                        <TableHead>
                          <TableRow>
                            <TableCell>Medicine</TableCell>
                          </TableRow>
                        </TableHead>
                        <TableBody>
                          {disease.medicines.map((medicine: any, _i: number) => (
                            <TableRow>
                              <TableCell>{medicine.name}</TableCell>
                            </TableRow>
                          ))}
                        </TableBody>
                      </Table>
                    </TableContainer>
                  </AccordionDetails>
                </Accordion>
              ))}
            </TabPanel>

            {/** Tumors */}
            <TabPanel value={value} index={2}>
              {patient && (
                <Typography variant="h5" component="h3">
                  Tumors list
                </Typography>
              )}
              {patient && (
                <>
                  {!loading ? (
                    <TumorList tumors={patient.tumors} patient={patient} reasons={reasons}/>
                  ) : (
                    <></>
                  )}{' '}
                </>
              )}
            </TabPanel>

            {/** Drugs */}
            <TabPanel value={value} index={3}>
              <TableContainer component={Paper}>
                <Table>
                  <TableHead>
                    <TableRow>
                      <TableCell>Drugs</TableCell>
                      <TableCell></TableCell>
                    </TableRow>
                  </TableHead>
                  <TableBody>
                    {patient.drugs.map((drug: any, i: number) => (
                      <TableRow>
                        <TableCell>{drug.name}</TableCell>
                        <TableCell>
                          <Button
                            size="small"
                            variant="contained"
                            color="secondary"
                            disabled={drug.end_date != null}
                            onClick={async () => {
                              setStopDrug({ drug: drug, index: i });
                            }}
                          >
                            Interrompi
                          </Button>
                        </TableCell>
                      </TableRow>
                    ))}
                  </TableBody>
                </Table>
              </TableContainer>

              {reasonDialog(
                (
                  patient_id: number,
                  drug_id: number,
                  ragioni: number[],
                  comment: string
                ) => {
                  setSubmitting(true);

                  connector.callGet(
                    'detach/' + patient_id + '/' + drug_id,
                    { reasons: JSON.stringify(ragioni), comment: comment ?? '' }
                  ).then((_data) => {
                      loadPatient();
                      setSubmitting(false);
                    })
                    .catch(console.log);
                }
              )}

            </TabPanel>

            <TabPanel value={value} index={4}>
              <JobsByPatientPage id={patient?.id} />
            </TabPanel>
            <Grid container justify="space-between">
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
                    history.push(
                      generatePath(Routes.PATIENTS_EDIT, { id: patient.id })
                    );
                  }}
                >
                  Edit
                </Button>
              </Grid>
            </Grid>
          </div>
        </>
      )}
    </Paper>
  );
}
