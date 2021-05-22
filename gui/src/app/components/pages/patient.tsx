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
  DiseaseEntity,
  DiseaseRepository,
  PatientEntity,
  PatientRepository,
} from '../../../api';
import {
  Gender,
  SimpleMapArray,
  TypeOfNotification,
} from '../../../interfaces';
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

import { Accordion, AccordionDetails, AccordionSummary, Dialog, DialogActions, DialogContent, DialogContentText, DialogTitle, Table, TableBody, TableCell, TableContainer, TableHead, TableRow } from "@material-ui/core";
import ExpandMoreIcon from '@material-ui/icons/ExpandMore';
import { useTheme } from '@material-ui/styles';
import Button, { SubmitButton } from '../ui/Button';
import { JobsByPatientPage } from '.';
import { Field, Form, Formik } from 'formik';
import { FormikSelect } from '../ui/Form/FormikSelect';

type MaybePatient = PatientEntity | undefined;
type MaybeDiseases = SimpleMapArray<DiseaseEntity> | undefined;

export default function PatientForm() {
  const classes = useStyles();
  const repository = useService(PatientRepository);
  const diseasesRepository = useService(DiseaseRepository);
  const [loading, setLoading] = useState(false);
  const [diseases, setDiseases] = useState<MaybeDiseases>();
  const [pathologies, setPathologies] = useState<any[]>([]);
  const [patient, setPatient] = useState<MaybePatient>();
  const [submitting, setSubmitting] = useState(false);
  const history = useHistory();
  const { id } = useParams<{ id?: string }>();
  const [open, setOpen] = useState(false);
  const [openTumorModal, setOpenTumorModal] = useState(false);

  const [tumors, setTumors] = useState<{id: number, name: string}[]>();
  const [tumorsOptions, setTumorOptions] = useState<{value: string, label:string}[]>();
  const [drugs, setDrugs] = useState<{id: number, name: string}[]>([]);


  const [pathologyElements, setPathologyElements] = useState<any[]>([]);
  const [selectedPathology, setSelectedPathology] = useState<any | false>(false);

  const [tumorElements, setTumorElements] = useState<any[]>([]);
  const [selectedTumor, setSelectedTumor] = useState<any | false>(false);

  const [pathologyChips, setPathologyChips] = useState<any>([]);
  const [pathologyModals, setPathologyModals] = useState<any>([]);

  const [openModal, setOpenModal] = useState<string| false>(false);

  const [testPatientPathology, setTestPatientPathology] = useState<SimpleMapArray<number[]>>({});

  const [value, setValue] = useState<number>(0);
  const [expanded, setExpanded] = React.useState<number | false>(false);
  const [stopDrug, setStopDrug] = React.useState<any>(false);


  const [update, setUpdate] = useState<number>(Math.random());


  function forceUpdate(){
    let v = Math.random();
    while (v == update) v = Math.random();
    setUpdate(v);
  }

  const theme = useTheme();

  useEffect(() => {
    runAsync(async () => {
      setLoading(true);
      if (id) {
        let p = await (await repository.fetch(+id)).refresh();
        setPatient(p);
        setDrugs(p.drugs);
      } else {
        setPatient(repository.new());

      }
      setLoading(false);
    });
  }, [id, repository]);

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
            <Typography>{children}</Typography>
          </Box>
        )}
      </div>
    );
  }

  useEffect(() => {
    fetch('http://localhost:8000/api/reasons').then(res => res.json()).then((data) => {
      setReasons(data.map((d: any) => {return {'id':d.id, 'name': d.name}}));
    }).catch(console.log);
   }, []);

  const [reasons, setReasons] = useState<{id:number, name:string}[]>([]);

  const backUrl = generatePath(Routes.PATIENTS);



  return (
    <Paper elevation={1} className={classes.paper} style={{padding:0, borderRadius:10}}>
      {loading || !patient ? (
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
        <AppBar position="static" style={{borderTopLeftRadius:10, borderTopRightRadius:10}}>
          <Tabs value={value} onChange={(event: React.ChangeEvent<{}>, newValue: number) => {
              setValue(newValue);
            }} aria-label="tabs">
            <Tab label="Anagrafica"/>
            <Tab label="Patologie pregresse"/>
            <Tab label="Tumori attuali"/>
            <Tab label="Drugs"/>
            <Tab label="Analyses"/>
          </Tabs>
        </AppBar>
        <div style={{padding:10}}>
        <Typography variant="h5" component="h3">Cartella clinica di {patient.fullName}</Typography>
        <TabPanel value={value} index={0}>

                <Grid container spacing={2}>
                  <Typography variant="overline" display="block" gutterBottom >
                    Patient code: {patient.code}
                  </Typography>
                </Grid>
                <Grid container spacing={2}>
                  <Grid item sm><Typography variant="overline" display="block" gutterBottom>Patient name: {patient.first_name}</Typography></Grid>
                  <Grid item sm><Typography variant="overline" display="block" gutterBottom >Patient surname: {patient.last_name}</Typography></Grid>
                </Grid>
                <Grid container spacing={2}>
                  <Grid item sm><Typography variant="overline" display="block" gutterBottom>Patient age: {patient.age}</Typography></Grid>
                  <Grid item sm><Typography variant="overline" display="block" gutterBottom >Patient gender: {patient.gender}</Typography></Grid>
                </Grid>
                <Grid container spacing={2}>
                  <Grid item sm><Typography variant="overline" display="block" gutterBottom>Patient email: {'email@email.com'}</Typography></Grid>
                </Grid>
                <Grid container spacing={2}>
                  <Grid item sm><Typography variant="overline" display="block" gutterBottom>Patient desease: {patient.disease.name}</Typography></Grid>
                </Grid>






        </TabPanel>
        <TabPanel value={value} index={1}>
        {patient.diseases.map((disease:any) =>
            <Accordion TransitionProps={{ unmountOnExit: true }} expanded={expanded == disease.id} onChange={ (event: React.ChangeEvent<{}>, isExpanded: boolean) =>{setExpanded( isExpanded ? disease.id : false)}}>
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
                    <TableHead><TableRow><TableCell>Medicine</TableCell></TableRow></TableHead>
                    <TableBody>
                      {disease.medicines.map((medicine:any, i:number) =>
                      <TableRow>
                        <TableCell>{medicine.name}</TableCell>
                      </TableRow>
                      )}
                    </TableBody>
                  </Table>
                </TableContainer>
              </AccordionDetails>
            </Accordion>
        )}
        </TabPanel>
        <TabPanel value={value} index={2}>
          {patient && (<Typography variant="h5" component="h3">Tumors list</Typography>)}
          {patient && (<>{!loading ? <TumorList tumors={patient.tumors} patient={patient}/> : <></>} </>)}
        </TabPanel>

            <TabPanel value={value} index={3}>
                <TableContainer component={Paper}>
                  <Table>
                    <TableHead><TableRow><TableCell>Drugs</TableCell><TableCell></TableCell></TableRow></TableHead>
                    <TableBody>
                      {patient.drugs.map((drug:any, i:number) =>
                      <TableRow>
                        <TableCell>{drug.name}</TableCell>
                        <TableCell><Button size="small" variant="contained" color="secondary" disabled={drug.end_date != null}
                          onClick={async () => {
                            setStopDrug({'drug':drug, index: i});
                          }}>Interrompi</Button>
                      </TableCell>
                      </TableRow>
                      )}
                    </TableBody>
                  </Table>
                </TableContainer>
                <Dialog open={stopDrug} onClose={() => {setStopDrug(false)}} aria-labelledby="form-dialog-title">
                  <DialogTitle id="form-dialog-title">Perchè interrompere {stopDrug ? stopDrug.drug.name : ''} ?</DialogTitle>
                  <Formik
                      initialValues={{ragioni:[]}}
                      onSubmit={(d) => {
                        alert(JSON.stringify(d));
                        setSubmitting(true);
                        console.log('url=' + 'http://localhost:8000/api/detach/'+patient.id+'/'+stopDrug.drug.id + '?reasons=' + JSON.stringify(reasons));
                        fetch('http://localhost:8000/api/detach/'+patient.id+'/'+stopDrug.drug.id + '?reasons=' + JSON.stringify(reasons.map(r => r.id)))
                            .then(res => res.json()).then((data) => {
                                                              alert(JSON.stringify(data.data));
                                                              //setDrugs(data.data);
                                                              runAsync(async () => {
                                                                setLoading(true);
                                                                setPatient(await (await repository.fetch(+id)).refresh());
                                                                setLoading(false);
                                                              });
                                                              setSubmitting(false);
                              }).catch(console.log);

                        setStopDrug(false);}} >
                    <Form>
                      <DialogContent>
                        <DialogContentText>Puoi selezionare una o più ragioni.</DialogContentText>
                        <Field name={'ragioni'} isMulti component={FormikSelect} options={reasons.map((r) => {return {'value':r.id, 'label':r.name}})} label="perchè"/>
                      </DialogContent>
                      <DialogActions>
                        <Button onClick={() => {setStopDrug(false)}} color="primary">Cancel</Button>
                        <SubmitButton  text="Save" isSaving={submitting}/>
                      </DialogActions>
                    </Form>
                  </Formik>
                </Dialog>
        </TabPanel>

        <TabPanel value={value} index={4}>
          <JobsByPatientPage id={patient.id}/>
        </TabPanel>
                    <Grid container justify="space-between">
                    <Grid item xs="auto">
                      <Button
                        variant="contained"
                        color="default"
                        href={backUrl}
                      >
                        <Icon className="fas fa-arrow-left" /> Go Back
                      </Button>
                    </Grid>
                    <Grid item xs="auto">
                      <Button color="primary" variant="contained" onClick={() => {history.push(generatePath(Routes.PATIENTS_EDIT, {id: patient.id,}));}}>Edit</Button>
                    </Grid>
                  </Grid>
                  </div>
        </>
      )}
    </Paper>
  );
}
