import React, { useEffect, useMemo, useState } from 'react';
import { useHistory, useParams } from 'react-router-dom';
import { createStyles, makeStyles } from '@material-ui/core/styles';
import { green } from '@material-ui/core/colors';
import {
  Box,
  CircularProgress,
  Divider,
  FormGroup,
  Grid,
  Icon,
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
  ResourceEntity,
  TumorRepository,
  DrugRepository,
  MedicineRepository,
  PathologyRepository,
  LocationRepository
} from '../../../../api';
import {
  Gender,
  Option,
  SimpleMapArray,
  TypeOfNotification,
} from '../../../../interfaces';
import { runAsync } from '../../utils';
import { useService } from '../../../../reactInjector';
import SelectField from '../../ui/Form/SelectField';
import TextField from '../../ui/Form/TextField';
import Button, { SubmitButton } from '../../ui/Button';
import Routes from '../../../../constants/routes.json';

import { FormikSelect } from '../../ui/Form/FormikSelect';
import Dialog from '@material-ui/core/Dialog';
import DialogTitle from '@material-ui/core/DialogTitle';
import { DialogContent } from '@material-ui/core';
import { DialogContentText } from '@material-ui/core';
import { DialogActions } from '@material-ui/core';
import Chip from '@material-ui/core/Chip';
import { Autocomplete } from '@material-ui/lab';
import { Tumor } from '../../../../interfaces/entities/tumor';
import { Pathology } from '../../../../interfaces/entities/pathology';

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
type MaybeResources = ResourceEntity[] | undefined;

type Options = Option[];
export default function PatientForm() {

  const classes = useStyles();
  const repository = useService(PatientRepository);
  const diseasesRepository = useService(DiseaseRepository);
  const drugsRepository = useService(DrugRepository);
  const tumorsRepository = useService(TumorRepository);
  const medicinesRepository = useService(MedicineRepository);
  const pathologiesRepository = useService(PathologyRepository);
  const locationsRepository = useService(LocationRepository);

  const [loading, setLoading] = useState(false);
  const [diseases, setDiseases] = useState<MaybeDiseases>();

  const [patient, setPatient] = useState<MaybePatient>();
  const [submitting, setSubmitting] = useState(false);
  const history = useHistory();
  const { id } = useParams<{ id?: string }>();
  const [open, setOpen] = useState(false);
  const [openTumorModal, setOpenTumorModal] = useState(false);

  const [pathologies, setPathologies] = useState<MaybeResources>();
  const [pathologyOptions, setPathologyOptions] = useState<Option[]>([]);

  const [tumors, setTumors] = useState<MaybeResources>();
  const [tumorsOptions, setTumorOptions] = useState<Option[]>([]);

  const [drugs, setDrugs] = useState<MaybeResources>();
  const [drugOptions, setDrugOptions] = useState<Option[]>([]);

  const [medicines, setMedicines] = useState<MaybeResources>();
  const [medicineOptions, setMedicineOptions] = useState<Options>([]);

  const [pathologyElements, setPathologyElements] = useState<Pathology[]>([]);
  const [selectedPathology, setSelectedPathology] = useState<Pathology>();
  const [showPathologyModal, setShowPathologyModal] = useState<boolean>(false);

  const [tumorElements, setTumorElements] = useState<Tumor[]>([]);
  const [selectedTumor, setSelectedTumor] = useState<Tumor>();
  const [showTumorModal, setShowTumorModal] = useState<boolean>(false);

  const [locations, setLocations] = useState<MaybeResources>();
  const [locationOptions, setLocationOptions] = useState<SimpleMapArray<string>>([]);

  const allowCommittedDrugDelete = false;


  useEffect(() => {
    runAsync(async () => {
      if (!locations) {
        setLoading(true);

        const tmp = await locationsRepository.fetchPage();

        let t = tmp.data.reduce<ResourceEntity[]>((map, d) => {
          map.push(d);
          return map;
        }, []);

        setLocations(t);

        setLocationOptions(
          tmp.data.reduce<SimpleMapArray<string>>((map, d) => {
            if (d.id) map[d.id] = d.name;
            return map;
          }, {})
        );

        setLoading(false);
      }
    });
  }, [diseases, diseasesRepository]);


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
        setLoading(false);
      }
    });
  }, [diseases, diseasesRepository]);

  useEffect(() => {
    runAsync(async () => {
      if (!pathologies) {
        setLoading(true);
        const tmp = await pathologiesRepository.fetchPage();
        // In realtà questo non serve.
        let t = tmp.data.reduce<ResourceEntity[]>((map, d) => {
          map.push(d);
          return map;
        }, []);
        setPathologies(t);

        setPathologyOptions(tmp.data.reduce<Option[]>((map, d) => {
          map.push({'value':d, 'label':d.name});
          return map;
        }, []));
        setLoading(false);
      }
    });
  }, [pathologies, PathologyRepository]);

  useEffect(() => {
    runAsync(async () => {
      if (!tumors) {
        setLoading(true);
        const tmp = await tumorsRepository.fetchPage();
        // In realtà questo non serve.
        let t = tmp.data.reduce<ResourceEntity[]>((map, d) => {
          map.push(d);
          return map;
        }, []);
        setTumors(t);

        setTumorOptions(tmp.data.reduce<Option[]>((map, d) => {
          map.push({'value':d, 'label':d.name});
          return map;
        }, []));
        setLoading(false);
      }
    });
  }, [tumors, TumorRepository]);

  useEffect(() => {
    runAsync(async () => {
      if (!drugs) {
        setLoading(true);
        const tmp = await drugsRepository.fetchPage();
        // In realtà questo non serve.
        let t = tmp.data.reduce<ResourceEntity[]>((map, d) => {
          map.push(d);
          return map;
        }, []);
        setDrugs(t);

        setDrugOptions(tmp.data.reduce<Option[]>((map, d) => {
          map.push({'value':d, 'label':d.name});
          return map;
        }, []));
        setLoading(false);
      }
    });
  }, [drugs, DrugRepository]);

  useEffect(() => {
    runAsync(async () => {
      if (!medicines) {
        setLoading(true);
        const tmp = await medicinesRepository.fetchPage();
        // In realtà questo non serve.
        let t = tmp.data.reduce<ResourceEntity[]>((map, d) => {
          map.push(d);
          return map;
        }, []);
        setMedicines(t);

        setMedicineOptions(tmp.data.reduce<Option[]>((map, d) => {
          map.push({'value':d, 'label':d.name});
          return map;
        }, []));
        setLoading(false);
      }
    });
  }, [medicines, MedicineRepository]);


  useEffect(() => {
    runAsync(async () => {
      setLoading(true);
      if (id) {
        let p = await (await repository.fetch(+id)).refresh();
        setPatient(p);
        setPathologyElements(p.diseases);
        setTumorElements(p.tumors)
      } else {
        setPatient(repository.new());
      }
      setLoading(false);

    });
  }, [id, repository]);


  const diseaseOptions = useMemo(() => {
    return Object.values(diseases || {}).reduce<SimpleMapArray<string>>(
      (map, d) => {
        if (d.id) map[d.id] = d.name;
        return map;
      },
      {}
    );
  }, [diseases]);



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
    disease: Yup.number().defined(),
    disease_stage: Yup.object({
        T: Yup.number().min(0).max(4).defined(),
        M: Yup.number().min(0).max(4).defined(),
        N: Yup.number().min(0).max(4).defined(),
      })
    .defined(),
    disease_site_id: Yup.number().defined(),

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
                //alert(JSON.stringify(d));
                d.diseases = pathologyElements.filter(p => p != null).map ((p) => {return {'id':p.id, 'medicines':p.medicines.map(m => m.id)}});
                d.tumors = tumorElements.map ( (tumor) => {
                  return {
                    'id'      : tumor.id,
                    'name'    : '',
                    'type'    : tumor.type,
                    'sede'    : tumor.sede.map (s => s.id),
                    'stadio'  : tumor.stadio,
                    'drugs'   : tumor.drugs.map( (drug) => {
                      return {
                        'id'          : drug.id,
                        'name'        : drug.name ?? '',
                        'start_date'  : drug.start_date,
                        'end_date'    : drug.end_date,
                        'reasons'     : drug.reasons?.map ( reason => reason.id )
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
                <Grid container spacing={2}>
                  <Grid item md>
                    <TextField label="Age" name="age" type="number" required />
                  </Grid>
                  <Grid item md>
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
                  </Grid>
                </Grid>

                <TextField label="Email" name="email" type="email" required />
                <TextField label="Fiscal Number" name="fiscalNumber" required />

                <SelectField
                  name="disease"
                  label="Disease"
                  emptyText="Select a Disease"
                  addEmpty={!patient.id}
                  options={diseaseOptions}
                  required
                />

                <Grid container spacing={3}>
                  <Grid item md>
                  <SelectField
                    name="disease_stage.T"
                    label="T"
                    emptyText="Select T"
                    addEmpty={true}
                    options={["0", "1", "2","3"]}
                    required
                  />
                  </Grid>
                  <Grid item md>
                  <SelectField
                    name="disease_stage.N"
                    label="N"
                    emptyText="Select N"
                    addEmpty={true}
                    options={["0", "1", "2","3"]}
                    required
                  /></Grid>
                  <Grid item md>
                  <SelectField
                    name="disease_stage.M"
                    label="M"
                    emptyText="Select M"
                    addEmpty={true}
                    options={["0", "1", "2","3"]}
                    required
                  /></Grid>
              </Grid>

              <Grid item md>
                    <SelectField
                      name="disease_site_id"
                      label="Site"
                      emptyText="Select a site"
                      addEmpty={true}
                      options={locationOptions}
                      required
                    />
                  </Grid>

                <Grid container>
                <div style={{padding:10}}><Typography variant="overline" display="block" gutterBottom>Patologie pregresse</Typography>
                { pathologyElements.map((pathology) => {
                    return (
                    <div style={{margin:'0.2em', display: 'inline-block'}} key={"p-" + pathology.id}>
                    <Chip
                      label={pathology.name}
                      onClick={() => {setSelectedPathology(pathology); setShowPathologyModal(true);}}
                      color="primary"
                      onDelete={() => {setPathologyElements(pathologyElements.filter((p) => {return p.id != pathology.id}))}}
                    /></div>);
                  })}</div>
                </Grid>

                <Grid container>
                  <Box style={{padding:10}}><Typography variant="overline" display="block" gutterBottom>Tumori</Typography>
                  { tumorElements.map((tumor) => {
                    return (
                    <div style={{margin:1, display: 'inline'}} key={"t-" + tumor.id}>
                    <Chip
                      label={tumor.name}
                      onClick={() => {setSelectedTumor(tumor); setShowTumorModal(true); }}
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

      <Dialog open={open} onClose={() => {setOpen(false)}} aria-labelledby="form-dialog-title">
        <DialogTitle id="form-dialog-title">Aggiungi patologie pregresse</DialogTitle>
        <Formik
            initialValues={{pathology:undefined, medicines: []}}
            onSubmit={(d) => {
              if(d.pathology !== null){
                const _pathologyElements = [...pathologyElements];
                _pathologyElements.push({'id':d.pathology.id, 'name':d.pathology.name, 'medicines':d.medicines});
                setPathologyElements(_pathologyElements);
              }
              setOpen(false);
            }}>
          <Form>
            <DialogContent style={{minWidth: 600}}>
              <DialogContentText>Seleziona la patologia pregressa.</DialogContentText>
              <Field name={'pathology'} component={FormikSelect} options={pathologyOptions} loading={loading} label="pahologies"
                getOptionDisabled={(option: Option) => {
                  for (let i = 0; i < pathologyElements.length; i++) {
                    if (pathologyElements[i].id == option.value.id) {return true;};
                  }
                  return false;
                }}
              />
              <DialogContentText>Seleziona i farmaci usati fino ad ora.</DialogContentText>
              <Field name={'medicines'} isMulti component={FormikSelect} options={medicineOptions} loading={loading} label="medicines"/>
            </DialogContent>
            <DialogActions>
              <Button onClick={() => {setOpen(false)}} color="primary">Cancel</Button>
              <SubmitButton onClick={() => {setOpen(false)}} color="primary">Confirm</SubmitButton>
            </DialogActions>
          </Form>
        </Formik>
      </Dialog>

      {/**  Aggiungiamo un nuovo tumore */}
      <Dialog open={openTumorModal} onClose={() => {setOpenTumorModal(false)}} aria-labelledby="form-dialog-title">
        <DialogTitle id="form-dialog-title">Aggiungi tumori</DialogTitle>
        <Formik
            validationSchema = {
              Yup.object().shape({
                tumor: Yup.object().defined().required(),
                type: Yup.mixed().oneOf(["primary", "secondary"]),
                T: Yup.number().min(0).max(4),
                M: Yup.number().min(0).max(4),
                N: Yup.number().min(0).max(4),
              })
            }
            initialValues={{tumor:undefined, drugs: [], sede: undefined, type:undefined, T:undefined, N:undefined,M:undefined,}}
            onSubmit={(d) => {

              if(d.tumor){
                const _tumorElements = [...tumorElements];
                _tumorElements.push({
                  'id'    : d.tumor.id,
                  'name'  : d.tumor.name,
                  'type'  : d.type,
                  'sede'  : d.sede !== undefined ? [{'id' : parseInt(d.sede ?? '')}] : [],
                  'stadio': {'T':d.T, 'N':d.N, 'M':d.M},
                  'drugs' : d.drugs
                });
                setTumorElements(_tumorElements);
              }
              //handleStopDrug(dialogData.index, dialogData.tumor, dialogData.drug, d.ragioni);
              //console.log(JSON.stringify(tumorElements));
              setOpenTumorModal(false);
              }} >
          <Form>
            <DialogContent>
              <DialogContentText>Seleziona il tumore da aggiungere.</DialogContentText>
              <Field name={'tumor'} component={FormikSelect}
                options={ tumorsOptions }
                loading={loading} label="tumors"
                getOptionDisabled={(option: Option) => {
                  for (let i = 0; i < tumorElements.length; i++) {
                    if (tumorElements[i].id == option.value.id) {return true;};
                  }
                  return false;
                }}
              />
              <DialogContentText>Vuoi aggiungere altre informazioni?</DialogContentText>

                <Grid container spacing={4}>
                  <Grid item md>
                    <SelectField
                      name="type"
                      label="Tipo"
                      emptyText="Select a type"
                      addEmpty={true}
                      options={{"primary":"primario", "secondary":"secondario"}}
                    />
                  </Grid>
                  <Grid item md>
                    <SelectField
                      name="sede"
                      label="Sede"
                      emptyText="Select a site"
                      addEmpty={true}
                      options={locationOptions}
                    />
                  </Grid>

                </Grid>

                <Grid container spacing={3}>
                  <Grid item md>
                  <SelectField
                    name="T"
                    label="T"
                    emptyText="Select T"
                    addEmpty={true}
                    options={["0", "1", "2","3"]}
                  />
                  </Grid>
                  <Grid item md>
                  <SelectField
                    name="N"
                    label="N"
                    emptyText="Select N"
                    addEmpty={true}
                    options={["0", "1", "2","3"]}
                  /></Grid>
                  <Grid item md>
                  <SelectField
                    name="M"
                    label="M"
                    emptyText="Select M"
                    addEmpty={true}
                    options={["0", "1", "2","3"]}
                  /></Grid>
              </Grid>

              <DialogContentText>Seleziona i farmaci usati fino ad ora.</DialogContentText>
              <Field
                name={'drugs'}
                isMulti
                component={FormikSelect}
                options={ drugOptions }
                loading={loading}
                label="drugs"
                />
            </DialogContent>
            <DialogActions>
              <Button onClick={() => {setOpenTumorModal(false)}} color="primary">Cancel</Button>
              <SubmitButton >Confirm</SubmitButton>
            </DialogActions>
          </Form>
        </Formik>
      </Dialog>



      <Dialog open={showPathologyModal} onClose={() => {setShowPathologyModal(false)}} aria-labelledby="form-dialog-title">
          <DialogTitle id="form-dialog-title">Aggiungi farmaci a {selectedPathology?.name}</DialogTitle>
          <Formik
              initialValues={{medicines: []}}
              onSubmit={(d) => {
                selectedPathology.medicines = d.medicines;
                setShowPathologyModal(false);
              }} >
            <Form>
              <DialogContent>
                <DialogContentText>Seleziona i farmaci usati fino ad ora.</DialogContentText>
                <Autocomplete
                  id="combo-box-demo"
                  options={medicineOptions}
                  getOptionLabel={(option) => option.label ?? ''}
                  defaultValue={ selectedPathology?.medicines.map( m => {return {'value':m, 'label':m.name ?? ''}} )}
                  getOptionDisabled={(option: Option) => {
                    for (let i = 0; i < selectedPathology?.medicines?.length; i++) {
                      if (selectedPathology.medicines[i].id == option.value.id) {return true;};
                    }
                    return false;
                  }}
                  autoComplete
                  autoHighlight
                  multiple
                  onChange={(e, value) => { selectedPathology.medicines = value.map((v) => v.value) }}
                  renderInput={(params) => <TextField {...params} label={'medicines'} name={ selectedPathology?.name ?? ''} variant="outlined" />}
               />
              </DialogContent>
              <DialogActions>
                <Button onClick={() => {setShowPathologyModal(false)}} color="primary">Cancel</Button>
                <Button onClick={() => {setShowPathologyModal(false)}} color="primary">Confirm</Button>
              </DialogActions>
            </Form>
          </Formik>
        </Dialog>






        <Dialog open={showTumorModal} onClose={() => {setShowTumorModal(false)}} aria-labelledby="form-dialog-title">
          <DialogTitle id="form-dialog-title">Modifica {selectedTumor?.name}</DialogTitle>
          <Formik
              initialValues={{
                drugs: [],
                type: selectedTumor?.type,
                sede: selectedTumor && selectedTumor.sede && selectedTumor.sede != [] && selectedTumor.sede[0] ? selectedTumor.sede[0].id.toLocaleString()  : undefined ,
                T: selectedTumor?.stadio ? selectedTumor?.stadio.T : undefined,
                N: selectedTumor?.stadio ? selectedTumor?.stadio.N : undefined,
                M: selectedTumor?.stadio ? selectedTumor?.stadio.M : undefined,
              }}
              onSubmit={(d) => {
                selectedTumor.type = d.type;
                selectedTumor.sede = d.sede ? [{'id': parseInt(d.sede)}] : [];
                selectedTumor.stadio.T = d.T ?? '';
                selectedTumor.stadio.N = d.N ?? '';
                selectedTumor.stadio.M = d.M ?? '';
                selectedTumor.drugs = selectedTumor.drugs;
                setShowTumorModal(false);
              }} >
            <Form>
              <DialogContent>
              <Divider variant="middle" />

              <label>Vuoi aggiungere altre informazioni?</label>
                <Grid container spacing={4}>
                  <Grid item md>
                    <SelectField
                      name="type"
                      label="Tipo"
                      emptyText="Select a type"
                      addEmpty={true}
                      options={{"primary":"primario", "secondary":"secondario"}}
                    />
                  </Grid>
                  <Grid item md>
                    <SelectField
                      name="sede"
                      label="Sede"
                      emptyText="Select a sede"
                      addEmpty={true}
                      options={locationOptions}
                    />
                  </Grid>

                </Grid>

                <Grid container spacing={3}>
                <Grid item md>
                <SelectField
                  name="T"
                  label="T"
                  emptyText="Select T"
                  addEmpty={true}
                  options={["0", "1", "2","3"]}
                />
                </Grid>
                <Grid item md>
                <SelectField
                  name="N"
                  label="N"
                  emptyText="Select N"
                  addEmpty={true}
                  options={["0", "1", "2","3"]}
                /></Grid>
                <Grid item md>
                <SelectField
                  name="M"
                  label="M"
                  emptyText="Select M"
                  addEmpty={true}
                  options={["0", "1", "2","3"]}
                /></Grid>
              </Grid>

                <DialogContentText>Seleziona i farmaci usati fino ad ora.</DialogContentText>
                <Autocomplete
                  id="combo-box-demo"
                  options={ drugOptions }
                  getOptionLabel = {(option) => option.label}
                  getOptionSelected = { (o1, o2) => {return o1.value.id == o2.value.id} }
                  defaultValue = { selectedTumor?.drugs?.map( drug => {return {'value': {'id' : drug.id, 'name': drug.name ?? ''}, 'label':drug.name ?? ''}}) }
                  getOptionDisabled={(option: Option) => {
                    for (let i = 0; i < selectedTumor?.drugs?.length; i++) {
                      if (selectedTumor.drugs[i].id == option.value.id) {return true;};
                    }
                    return false;
                  }}
                  autoComplete
                  autoHighlight
                  multiple
                  onChange={ (e, value) => { selectedTumor.drugs = value.map((v) => v.value) }}
                  renderInput={(params) => <TextField {...params} label={'drugs'} name={selectedTumor?.name ?? ''} variant="outlined" />}
                  renderTags={(tagValue, getTagProps) =>
                    tagValue.map((option, index) => (
                      <Chip
                        label={option.label}
                        {...getTagProps({ index })}
                        disabled={selectedTumor?.drugs.filter(d => d.id == option.value.id)[0].end_date != null || allowCommittedDrugDelete }
                      />
                    ))
                  }
               />
               <Typography variant="overline" color="secondary">*Rimuovere i farmaci da qui per cancellarli dalla storia del paziente anzichè interromperli.</Typography>
              </DialogContent>
              <DialogActions>
                <Button onClick={() => {setShowTumorModal(false)}} color="primary">Cancel</Button>
                <SubmitButton color="primary">Confirm</SubmitButton>
              </DialogActions>
            </Form>
          </Formik>
        </Dialog>

    </Paper>
  );
}
