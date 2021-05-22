import React, { useEffect, useMemo, useState } from 'react';
import { useHistory, useParams } from 'react-router-dom';
import { createStyles, makeStyles } from '@material-ui/core/styles';
import { green } from '@material-ui/core/colors';
import {
  Box,
  CircularProgress,
  FormGroup,
  Grid,
  Icon,
  Modal,
  Paper,
  Typography,
} from '@material-ui/core';
import { Field, Form, Formik } from 'formik';
import * as Yup from 'yup';
import { generatePath } from 'react-router';
import {
  DiseaseEntity,
  DiseaseRepository,
  PatientEntity,
  PatientRepository,
} from '../../../../api';
import {
  Gender,
  SimpleMapArray,
  TypeOfNotification,
} from '../../../../interfaces';
import { runAsync } from '../../utils';
import { useService } from '../../../../reactInjector';
import SelectField from '../../ui/Form/SelectField';
import TextField from '../../ui/Form/TextField';
import Button, { SubmitButton } from '../../ui/Button';
import Routes from '../../../../constants/routes.json';

import TumorField from './tumorForm';
import { FormikSelect } from '../../ui/Form/FormikSelect';
import { tmp } from '../../../../api/transferManager';
import Dialog from '@material-ui/core/Dialog';
import DialogTitle from '@material-ui/core/DialogTitle';
import { DialogContent } from '@material-ui/core';
import { DialogContentText } from '@material-ui/core';
import { DialogActions } from '@material-ui/core';
import Chip from '@material-ui/core/Chip';
import { isNullOrUndefined } from 'util';
import { Autocomplete } from '@material-ui/lab';

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
  const [drugs, setDrugs] = useState<{id: number, name: string}[]>();


  const [pathologyElements, setPathologyElements] = useState<any[]>([]);
  const [selectedPathology, setSelectedPathology] = useState<any | false>(false);

  const [tumorElements, setTumorElements] = useState<any[]>([]);
  const [selectedTumor, setSelectedTumor] = useState<any | false>(false);

  const [pathologyChips, setPathologyChips] = useState<any>([]);
  const [pathologyModals, setPathologyModals] = useState<any>([]);

  const [openModal, setOpenModal] = useState<string| false>(false);

  const [testPatientPathology, setTestPatientPathology] = useState<SimpleMapArray<number[]>>({});


  useEffect(() => {
    runAsync(async () => {
      if (!diseases) {
        setLoading(true);
        const tmp = await diseasesRepository.fetchPage();
        setDiseases(
          tmp.data.reduce<SimpleMapArray<DiseaseEntity>>((map, d) => {
            if (d.id) map[d.id] = d;
            return map;
          }, {})
        );
        setPathologies(tmp.data.map((d) => {return {'value': {'id': d.id, 'name':d.name}, 'label':d.name}}))
        setLoading(false);
      }
    });
  }, [diseases, diseasesRepository]);

  useEffect(() => {
    runAsync(async () => {
      setLoading(true);
      if (id) {


        let p = await (await repository.fetch(+id)).refresh();

        setPatient(p);
        //setPathologyElements((await (await repository.fetch(+id)).refresh()).diseases);
        //let tmp = await (await repository.fetch(+id)).refresh();
        setPathologyElements(p.diseases);
        setTumorElements(p.tumors)
        //console.log(JSON.stringify (((tmp.diseases.map( d => d.name )))));
      } else {
        setPatient(repository.new());
      }
      setLoading(false);

    });
  }, [id, repository]);

  // const diseaseIds = useMemo(() => Object.keys(diseases || {}).map((x) => +x), [
  //   diseases,
  // ]);
  const diseaseOptions = useMemo(() => {
    return Object.values(diseases || {}).reduce<SimpleMapArray<string>>(
      (map, d) => {
        if (d.id) map[d.id] = d.name;
        return map;
      },
      {}
    );
  }, [diseases]);


  useEffect(() => {
    fetch('http://localhost:8000/api/tumors').then(res => res.json()).then((data) => {
      setTumors(data.data);
      setTumorOptions(data.data.map((d: any) => {return {'value':d.id, 'label': d.name}}))
    }).catch(console.log);
   }, []);

   useEffect(() => {
     fetch('http://localhost:8000/api/drugs').then(res => res.json()).then((data) => {
       setDrugs(data.data.map((d: any) => {return {'value':d.id, 'label': d.name}}));
     }).catch(console.log);
    }, []);



  const validationSchema = Yup.object().shape({
    code: Yup.string()
      .defined()
      .max(255)
      .matches(/^[A-Za-z0-9_]+$/, {
        message: 'The field must contain only letters, numbers, and dashes.',
      }),
    first_name: Yup.string().defined().max(255),
    last_name: Yup.string().defined().max(255),
    age: Yup.number().min(0).max(100),
    gender: Yup.mixed()
      .oneOf([Gender.m, Gender.f] as Gender[])
      .defined(),
    //disease: Yup.number().defined(),
  });

  const backUrl = generatePath(Routes.PATIENTS);






  return (
    <Paper elevation={1} className={classes.paper}>
      {loading || !patient || !diseases ? (
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
          {patient && diseases && (
            <Typography variant="h5" component="h3">
              {patient.id ? 'Edit Patient' : 'New Patient'}
            </Typography>
          )}
          <Typography component="p" />
          {patient && diseases && (
            <Formik
              initialValues={patient.toDataObject()}
              validationSchema={validationSchema}
              onSubmit={async (d) => {
                //console.log(JSON.stringify(testPatientPathology));

                //d.diseases = testPatientPathology;
                d.diseases = pathologyElements.filter(p => p != null).map ((p) => {return {'id':p.id, 'medicines':p.medicines.map(m => m.id)}});
                d.tumors = tumorElements.map ( (tumor) => {
                  console.log(JSON.stringify(tumor.sede));
                  return {
                    'id' : tumor.id,
                    'type' : tumor.type,
                    'sede' : tumor.sede.map (s => s.id),
                    'stadio' : tumor.stadio,
                    'drugs' : tumor.drugs.map( (drug) => {
                      return {
                        'id' : drug.id,
                        'start_date' : drug.start_date,
                        'end_date' : drug.end_date,
                        'reasons' : drug.reasons.map ( reason => reason.id )
                      }
                    })
                  }

                } );

                return runAsync(async (manager) => {
                  setSubmitting(true);
                  await patient?.fill(d).save();
                  repository.refreshAllPages();
                  manager.pushSimple(
                    'Patient saved!',
                    TypeOfNotification.success
                  );
                  history.push(backUrl);
                });


              }}
            >



              <Form>
                <TextField label="Patient Code" name="code" required />
                <Grid container spacing={2}>
                  <Grid item md>
                    <TextField label="First Name" name="first_name" required />
                  </Grid>
                  <Grid item md>
                    <TextField label="Last Name" name="last_name" required />
                  </Grid>
                </Grid>
                <TextField label="Age" name="age" type="number" required />
                <SelectField
                  name="gender"
                  label="Gender"
                  emptyText="Select a Gender"
                  addEmpty={!patient.id}
                  options={{
                    [Gender.m]: 'Male',
                    [Gender.f]: 'Female',
                  }}
                />
                <SelectField
                  name="disease"
                  label="Disease"
                  emptyText="Select a Disease"
                  addEmpty={!patient.id}
                  options={diseaseOptions}
                />

                <Grid container>
                <div style={{padding:10}}><Typography variant="overline" display="block" gutterBottom>Patologie pregresse</Typography>
                { pathologyElements.map((pathology) => {
                    return (
                    <div style={{margin:'0.2em', display: 'inline-block'}}>
                    <Chip
                      label={pathology.name}
                      onClick={() => {setSelectedPathology(pathology)}}
                      color="primary"
                      onDelete={() => {setPathologyElements(pathologyElements.filter((p) => {return p.id != pathology.id}))}}
                    /></div>);
                  })}</div>
                </Grid>

                <Grid container>
                  <Box style={{padding:10}}><Typography variant="overline" display="block" gutterBottom>Tumori</Typography>
                  { tumorElements.map((tumor) => {
                    return (
                    <div style={{margin:1, display: 'inline'}}>
                    <Chip
                      label={tumor.name}
                      onClick={() => {setSelectedTumor(tumor)}}
                      color="secondary"
                      onDelete={() => {setTumorElements(tumorElements.filter((p) => {return p.id != tumor.id}))}}
                    /></div>);
                  })}</Box>
                </Grid>

                <Grid container justify="space-between" >
                    <Grid item xs="auto" style={{padding: 15, paddingLeft: 10}}>
                        <Button onClick={() => {setOpen(true)}} variant="contained" color="primary">Aggiungi patologie</Button>
                    </Grid>
                    <Grid item xs="auto" style={{padding: 15}}>
                      <Button onClick={() => {setOpenTumorModal(true)}} variant="contained" color="secondary">Aggiungi tumori</Button>
                    </Grid>
                  </Grid>

                <FormGroup row className={classes.formControl}>
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
                      <SubmitButton text="Save" isSaving={submitting} />
                    </Grid>
                  </Grid>
                </FormGroup>
              </Form>
            </Formik>



          )}
        </>
      )}



            {/**
            <div>{pathologyElements}</div>
            <Formik
              initialValues={{id:null}}
              onSubmit={(d) => {


                testPatientPathology[d.id.id] = [];
                let tmp = [...pathologyElements];
                tmp.push(
                  <Formik
                    initialValues={{drugs:[]}}

                    onSubmit={(dd) => {
                      alert(JSON.stringify('Aggiungiamo a ' + d.id.name+ ' Questi farmaci ' + JSON.stringify(dd.drugs)));
                      testPatientPathology[d.id.id] = dd.drugs.map((drug) => {return drug.id});
                      console.log(JSON.stringify(testPatientPathology));
                    }}
                  ><Form>
                    <Field name={'drugs'} component={FormikSelect} isMulti options={pathologies} loading={loading} label={"Selezione farmaci usati per curare " + d.id.name}
                      onChangeCallback={(drugs) => {
                        testPatientPathology[d.id.id] = drugs.map((value) => value.value.id);
                        console.log('nuovo valore per test: ' + JSON.stringify(testPatientPathology));
                      }} />
                    <SubmitButton text="Save drugs" isSaving={submitting} />
                  </Form></Formik>
                );
                setPathologyElements(tmp);
                console.log('test: ' + JSON.stringify(testPatientPathology));
              }}
            ><Form>
              <Field name={'id'} component={FormikSelect} options={pathologies} loading={loading} label="Selezione patologie pregresse"/>
              <SubmitButton text="Save pathology" isSaving={submitting} />
            </Form></Formik>
               */}

{/*
      <div style={{padding:10}}><Typography variant="overline" display="block" gutterBottom>Patologie pregresse</Typography>{ pathologyElements.map((pathology) => {
        return (
        <div style={{margin:'0.2em', display: 'inline-block'}}>
        <Chip
          label={pathology.name}
          onClick={() => {setSelectedPathology(pathology)}}
          color="primary"
          onDelete={() => {setPathologyElements(pathologyElements.filter((p) => {return p.id != pathology.id}))}}
        /></div>);
      })}</div>
    */}

{/*
      <Box style={{padding:10}}><Typography variant="overline" display="block" gutterBottom>Tumori</Typography>  { tumorElements.map((tumor) => {
        return (
        <div style={{margin:1, display: 'inline'}}>
        <Chip
          label={tumor.name}
          onClick={() => {setSelectedTumor(tumor)}}
          color="secondary"
          onDelete={() => {setTumorElements(tumorElements.filter((p) => {return p.id != tumor.id}))}}
        /></div>);
      })}</Box>
*/}

      <div>{pathologyElements.map((pathology) => {
        var values = pathology.medicines;
        console.log(JSON.stringify(values));
        return (
          <Dialog open={selectedPathology == pathology} onClose={() => {setSelectedPathology(false)}} aria-labelledby="form-dialog-title">
          <DialogTitle id="form-dialog-title">Aggiungi farmaci a {selectedPathology.name}</DialogTitle>
          <Formik
              initialValues={{medicines: []}}
              onSubmit={(d) => {
                alert('cambiamo ' + JSON.stringify(selectedPathology.medicines) + ' in ' + JSON.stringify(d.medicines));
                selectedPathology.medicines = d.medicines;
                setSelectedPathology(false);}} >
            <Form>
              <DialogContent>
                <DialogContentText>Seleziona i farmaci usati fino ad ora.</DialogContentText>
                <Autocomplete
                  id="combo-box-demo"
                  options={pathologies}
                  getOptionLabel={(option) => option.label}
                  //style={{ width: 300 }}
                  defaultValue={pathology.medicines.map( (m) => {return {'value':m, 'label':m.name}} )}
                  autoComplete
                  autoHighlight
                  multiple

                  onChange={(e, value) => { values = value.map((v) => v.value); alert(JSON.stringify(values))}}
                  renderInput={(params) => <TextField {...params} label={'medicines'} name={pathology.name} variant="outlined" />}
               />
              </DialogContent>
              <DialogActions>
                <Button onClick={() => {setSelectedPathology(false)}} color="primary">Cancel</Button>
                <Button onClick={() => {setSelectedPathology(false); selectedPathology.medicines = values; console.log(JSON.stringify(pathologyElements))}} color="primary">Save</Button>
              </DialogActions>
            </Form>
          </Formik>
        </Dialog>
        );
      })}</div>


      <div>{tumorElements.map((tumor) => {
        var values = tumor.drugs;

        return (
          <Dialog open={selectedTumor == tumor} onClose={() => {setSelectedTumor(false)}} aria-labelledby="form-dialog-title">
          <DialogTitle id="form-dialog-title">Modifica {selectedTumor.name}</DialogTitle>
          <Formik
              initialValues={{drugs: [], type: tumor?.type, sede: tumor && tumor.sede && tumor.sede != [] && tumor.sede[0] ? tumor.sede[0].id : null , T: tumor?.stadio ? tumor?.stadio.T : null, N: tumor?.stadio ? tumor?.stadio.N : null, M: tumor?.stadio ? tumor?.stadio.M : null,}}
              onSubmit={(d) => {
                alert('cambiamo ' + JSON.stringify(selectedTumor) + ' in ' + JSON.stringify(d.sede));
                selectedTumor.type = d.type;
                selectedTumor.sede = [{'id': parseInt(d.sede)}];
                selectedTumor.stadio.T = d.T;
                selectedTumor.stadio.N = d.N;
                selectedTumor.stadio.M = d.M;
                selectedTumor.drugs = values;
                setSelectedTumor(false);
              }} >
            <Form>
              <DialogContent>

              <label>Vuoi aggiungere altre informazioni?</label>
                <Grid container spacing={4}>
                  <Grid item md>
                    <SelectField
                      name="type"
                      label="Tipo"
                      emptyText="Select a type"
                      addEmpty={false}
                      options={{"primary":"primario", "secondary":"secondario"}}
                    />
                  </Grid>
                  <Grid item md>
                    <SelectField
                      name="sede"
                      label="Sede"
                      emptyText="Select a sede"
                      addEmpty={false}
                      options={{2:"sede 2", 1:"sede 1", 3:"sede 3"}}
                    />
                  </Grid>

                </Grid>

                <Grid container spacing={3}>
                <Grid item md>
                <SelectField
                  name="T"
                  label="T"
                  emptyText="Select T"
                  addEmpty={false}
                  options={["0", "1", "2","3"]}
                />
                </Grid>
                <Grid item md>
                <SelectField
                  name="N"
                  label="N"
                  emptyText="Select N"
                  addEmpty={false}
                  options={["0", "1", "2","3"]}
                /></Grid>
                <Grid item md>
                <SelectField
                  name="M"
                  label="M"
                  emptyText="Select M"
                  addEmpty={false}
                  options={["0", "1", "2","3"]}
                /></Grid>
              </Grid>

                <DialogContentText>Seleziona i farmaci usati fino ad ora.</DialogContentText>
                <Autocomplete
                  id="combo-box-demo"
                  options={drugs?.map((d) => {return {'value':{'id':d.value, 'name':d.label, 'start_date':null, 'end_date':null, 'reasons':[]}, 'label':d.label}})}
                  getOptionLabel={(option) => option.label}
                  //style={{ width: 300 }}
                  defaultValue={tumor.drugs.map( (m) => {return {'value':m, 'label':m.name}} )}
                  autoComplete
                  autoHighlight
                  multiple


                  onChange={(e, value) => { values = value.map((v) => v.value); alert(JSON.stringify(values))}}
                  renderInput={(params) => <TextField {...params} label={'drugs'} name={tumor.name} variant="outlined" />}
               />
              </DialogContent>
              <DialogActions>
                <Button onClick={() => {setSelectedTumor(false)}} color="primary">Cancel</Button>
                <SubmitButton onClick={() => {setSelectedTumor(false); selectedTumor.drugs = values; console.log(JSON.stringify(tumorElements))}} color="primary">Save</SubmitButton>
              </DialogActions>
            </Form>
          </Formik>
        </Dialog>
        );
      })}</div>
{/**

      <Button onClick={() => {setOpen(true)}} variant="contained" color="primary">Aggiungi patologie</Button>
 */}
      <Dialog open={open} onClose={() => {setOpen(false)}} aria-labelledby="form-dialog-title">
        <DialogTitle id="form-dialog-title">Aggiungi cose</DialogTitle>
        <Formik
            initialValues={{pathology:null, medicines: []}}
            onSubmit={(d) => {
              alert(JSON.stringify(d));
              if(d.pathology !== null){
                const _pathologyElements = [...pathologyElements];
                _pathologyElements.push({'id':d.pathology.id, 'name':d.pathology.name, 'medicines':d.medicines});
                //_pathologyElements[d.pathology.id] = {'id':d.pathology.id, 'name':d.pathology.name, 'medicines':d.medicines};
                setPathologyElements(_pathologyElements);
              }

              //handleStopDrug(dialogData.index, dialogData.tumor, dialogData.drug, d.ragioni);
              setOpen(false);}} >
          <Form>
            <DialogContent style={{minWidth: 600}}>
              <DialogContentText>Seleziona la patologia pregressa.</DialogContentText>
              <Field name={'pathology'} component={FormikSelect} options={pathologies} loading={loading} label="pahologies"
                getOptionDisabled={(option) => {
                  for (let i = 0; i < pathologyElements.length; i++) {
                    if (pathologyElements[i].id == option.value.id) {return true;};
                  }
                  return false;
                }}
              />
              <DialogContentText>Seleziona i farmaci usati fino ad ora.</DialogContentText>
              <Field name={'medicines'} isMulti component={FormikSelect} options={pathologies} loading={loading} label="medicines"/>
            </DialogContent>
            <DialogActions>
              <Button onClick={() => {setOpen(false)}} color="primary">Cancel</Button>
              <SubmitButton onClick={() => {setOpen(false)}} color="primary">Save</SubmitButton>
            </DialogActions>
          </Form>
        </Formik>
      </Dialog>

      {/**  Aggiungiamo un nuovo tumore */}
      <Dialog open={openTumorModal} onClose={() => {setOpenTumorModal(false)}} aria-labelledby="form-dialog-title">
        <DialogTitle id="form-dialog-title">Aggiungi tumori</DialogTitle>
        <Formik
            initialValues={{tumor:null, drugs: [], sede: null, type:null, T:null, N:null,M:null,}}
            onSubmit={(d) => {
              alert(JSON.stringify(d));

              const _tumorElements = [...tumorElements];
              _tumorElements.push({
                'id':d.tumor.id,
                'name':d.tumor.name,
                'type':d.type,
                'sede': [{'id' : parseInt(d.sede)}],
                'stadio': {'T':d.T, 'N':d.N, 'M':d.M},
                'drugs': d.drugs
              });
              setTumorElements(_tumorElements);

              //handleStopDrug(dialogData.index, dialogData.tumor, dialogData.drug, d.ragioni);
              console.log(JSON.stringify(tumorElements));
              setOpenTumorModal(false);}} >
          <Form>
            <DialogContent>
              <DialogContentText>Seleziona il tumore da aggiungere.</DialogContentText>
              <Field name={'tumor'} component={FormikSelect}
              options={tumors?.map( t => {return { 'value':t, 'label':t.name}})}
              loading={loading} label="tumors"
                getOptionDisabled={(option) => {
                  //return false;
                  for (let i = 0; i < tumorElements.length; i++) {
                    if (tumorElements[i].id == option.value.id) {return true;};
                  }
                  return false;
                }}
              />

              <label>Vuoi aggiungere altre informazioni?</label>
                <Grid container spacing={4}>
                  <Grid item md>
                    <SelectField
                      name="type"
                      label="Tipo"
                      emptyText="Select a type"
                      addEmpty={false}
                      options={{"primary":"primario", "secondary":"secondario"}}
                    />
                  </Grid>
                  <Grid item md>
                    <SelectField
                      name="sede"
                      label="Sede"
                      emptyText="Select a sede"
                      addEmpty={false}
                      options={{2:"sede 2", 1:"sede 1", 3:"sede 3"}}
                    />
                  </Grid>

                </Grid>

                <Grid container spacing={3}>
                <Grid item md>
                <SelectField
                  name="T"
                  label="T"
                  emptyText="Select T"
                  addEmpty={false}
                  options={["0", "1", "2","3"]}
                />
                </Grid>
                <Grid item md>
                <SelectField
                  name="N"
                  label="N"
                  emptyText="Select N"
                  addEmpty={false}
                  options={["0", "1", "2","3"]}
                /></Grid>
                <Grid item md>
                <SelectField
                  name="M"
                  label="M"
                  emptyText="Select M"
                  addEmpty={false}
                  options={["0", "1", "2","3"]}
                /></Grid>
              </Grid>

              <DialogContentText>Seleziona i farmaci usati fino ad ora.</DialogContentText>
              <Field name={'drugs'} isMulti component={FormikSelect}
              options={drugs?.map((d) => {return {'value':{'id':d.value, 'name':d.label, 'start_date':null, 'end_date':null, 'reasons':[]}, 'label':d.label}})}
              loading={loading} label="drugs"/>
            </DialogContent>
            <DialogActions>
              <Button onClick={() => {setOpenTumorModal(false)}} color="primary">Cancel</Button>
              <SubmitButton onClick={() => {setOpenTumorModal(false)}} color="primary">Save</SubmitButton>
            </DialogActions>
          </Form>
        </Formik>
      </Dialog>


    </Paper>
  );
}
