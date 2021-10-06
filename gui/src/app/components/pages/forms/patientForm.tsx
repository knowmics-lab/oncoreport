import React, { useMemo, useState } from 'react';
import { useHistory, useParams } from 'react-router-dom';
import { createStyles, makeStyles } from '@material-ui/core/styles';
import { green } from '@material-ui/core/colors';
import {
  Box,
  CircularProgress,
  FormGroup,
  Grid,
  Icon,
  Paper,
  Typography,
} from '@material-ui/core';
import { Form, Formik } from 'formik';
import * as Yup from 'yup';
import { generatePath } from 'react-router';
import Chip from '@material-ui/core/Chip';
import {
  DiseaseEntity,
  DiseaseRepository,
  PatientEntity,
  PatientRepository,
  LocationRepository,
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
import { Tumor } from '../../../../interfaces/entities/tumor';
import { Pathology } from '../../../../interfaces/entities/pathology';
import useAsyncEffect from '../../../hooks/useAsyncEffect';
import AddPreviousDiseasesDialog from '../../ui/PatientForm/AddPreviousDiseasesDialog';
import AddPreviousTumorDialog from '../../ui/PatientForm/AddPreviousTumorDialog';
import EditPreviousDiseasesDialog from '../../ui/PatientForm/EditPreviousDiseasesDialog';
import EditPreviousTumorDialog from '../../ui/PatientForm/EditPreviousTumorDialog';
import useRawRepositoryFetch from '../../../hooks/useRawRepositoryFetch';

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

function useValidationSchema() {
  return Yup.object().shape({
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
    telephone: Yup.string(),
    city: Yup.string(),
    disease: Yup.number().defined(),
    disease_stage: Yup.object({
      T: Yup.number().min(0).max(4).defined(),
      M: Yup.number().min(0).max(4).defined(),
      N: Yup.number().min(0).max(4).defined(),
    }).defined(),
    disease_site_id: Yup.number().defined(),
  });
}

export default function PatientForm() {
  const classes = useStyles();
  const repository = useService(PatientRepository);

  const [loading, setLoading] = useState(false);

  const [patient, setPatient] = useState<MaybePatient>();
  const [submitting, setSubmitting] = useState(false);
  const history = useHistory();
  const { id } = useParams<{ id?: string }>();
  const [open, setOpen] = useState(false);
  const [openTumorModal, setOpenTumorModal] = useState(false);

  const [pathologyElements, setPathologyElements] = useState<Pathology[]>([]);
  const [selectedPathology, setSelectedPathology] = useState<number>(-1);
  const [showPathologyModal, setShowPathologyModal] = useState<boolean>(false);

  const [tumorElements, setTumorElements] = useState<Tumor[]>([]);
  const [selectedTumor, setSelectedTumor] = useState<number>(-1);
  const [showTumorModal, setShowTumorModal] = useState<boolean>(false);

  const [loadingLocations, locations] = useRawRepositoryFetch(
    LocationRepository,
    (data) =>
      data.data.reduce((map: SimpleMapArray<string>, d) => {
        if (d.id) map[d.id] = d.name;
        return map;
      }, {}),
    {}
  );

  const [loadingDiseases, diseases] = useRawRepositoryFetch(
    DiseaseRepository,
    (data) =>
      data.data.reduce((map: SimpleMapArray<DiseaseEntity>, d) => {
        if (d.id) map[d.id] = d;
        return map;
      }, {}),
    {}
  );

  useAsyncEffect(async () => {
    setLoading(true);
    if (id) {
      const p = await (await repository.fetch(+id)).refresh();
      setPatient(p);
      setPathologyElements(p.diseases);
      setTumorElements(p.tumors);
    } else {
      setPatient(repository.new());
    }
    setLoading(false);
  }, [id, repository]);

  const realLoading = loading || loadingLocations || loadingDiseases;

  const diseaseOptions = useMemo(() => {
    return Object.values(diseases || {}).reduce<SimpleMapArray<string>>(
      (map, d) => {
        if (d.id) map[d.id] = d.name;
        return map;
      },
      {}
    );
  }, [diseases]);

  const validationSchema = useValidationSchema();

  const backUrl = generatePath(Routes.PATIENTS);

  return (
    <Paper elevation={1} className={classes.paper}>
      {realLoading || !patient || !diseases ? (
        <>
          <Grid container justifyContent="center">
            <Grid item xs="auto">
              <CircularProgress color="inherit" />
            </Grid>
          </Grid>
          <Grid container justifyContent="center">
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
                d.diseases = pathologyElements
                  .filter((p) => p != null)
                  .map((p) => {
                    return {
                      id: p.id,
                      medicines: p.medicines.map((m) => m.id),
                    };
                  });
                d.tumors = tumorElements.map((tumor) => {
                  return {
                    id: tumor.id,
                    name: '',
                    type: tumor.type,
                    sede: tumor.sede.map((s) => s.id),
                    stadio: tumor.stadio,
                    drugs: tumor.drugs.map((drug) => {
                      return {
                        id: drug.id,
                        name: drug.name ?? '',
                        start_date: drug.start_date,
                        end_date: drug.end_date,
                        reasons: drug.reasons?.map((reason) => reason.id),
                      };
                    }),
                  };
                });

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
                <TextField label="Telephone" name="telephone" type="string" />
                <TextField label="City" name="city" />
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
                      addEmpty
                      options={['0', '1', '2', '3']}
                      required
                    />
                  </Grid>
                  <Grid item md>
                    <SelectField
                      name="disease_stage.N"
                      label="N"
                      emptyText="Select N"
                      addEmpty
                      options={['0', '1', '2', '3']}
                      required
                    />
                  </Grid>
                  <Grid item md>
                    <SelectField
                      name="disease_stage.M"
                      label="M"
                      emptyText="Select M"
                      addEmpty
                      options={['0', '1', '2', '3']}
                      required
                    />
                  </Grid>
                </Grid>

                <Grid item md>
                  <SelectField
                    name="disease_site_id"
                    label="Site"
                    emptyText="Select a site"
                    addEmpty
                    options={locations}
                    required
                  />
                </Grid>

                <Grid container>
                  <div style={{ padding: 10 }}>
                    <Typography variant="overline" display="block" gutterBottom>
                      Previous diseases
                    </Typography>
                    {pathologyElements.map((pathology, i) => (
                      <div
                        style={{ margin: '0.2em', display: 'inline-block' }}
                        key={`p-${pathology.id}`}
                      >
                        <Chip
                          label={pathology.name}
                          onClick={() => {
                            setSelectedPathology(i);
                            setShowPathologyModal(true);
                          }}
                          color="primary"
                          onDelete={() => {
                            setPathologyElements(
                              pathologyElements.filter((p) => {
                                return p.id !== pathology.id;
                              })
                            );
                          }}
                        />
                      </div>
                    ))}
                  </div>
                </Grid>

                <Grid container>
                  <Box style={{ padding: 10 }}>
                    <Typography variant="overline" display="block" gutterBottom>
                      Previous tumors
                    </Typography>
                    {tumorElements.map((tumor, i) => (
                      <div
                        style={{ margin: 1, display: 'inline' }}
                        key={`t-${tumor.id}`}
                      >
                        <Chip
                          label={tumor.name}
                          onClick={() => {
                            setSelectedTumor(i);
                            setShowTumorModal(true);
                          }}
                          color="secondary"
                          onDelete={() => {
                            setTumorElements(
                              tumorElements.filter((p) => {
                                return p.id !== tumor.id;
                              })
                            );
                          }}
                        />
                      </div>
                    ))}
                  </Box>
                </Grid>

                <Grid container justifyContent="space-between">
                  <Grid item xs="auto" style={{ padding: 15, paddingLeft: 10 }}>
                    <Button
                      onClick={() => {
                        setOpen(true);
                      }}
                      variant="contained"
                      color="primary"
                    >
                      Add previous disease
                    </Button>
                  </Grid>
                  <Grid item xs="auto" style={{ padding: 15 }}>
                    <Button
                      onClick={() => {
                        setOpenTumorModal(true);
                      }}
                      variant="contained"
                      color="secondary"
                    >
                      Add previous tumor
                    </Button>
                  </Grid>
                </Grid>

                <FormGroup row className={classes.formControl}>
                  <Grid container justifyContent="space-between">
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

      <AddPreviousDiseasesDialog
        open={open}
        setOpen={setOpen}
        selectedPathologies={pathologyElements}
        onPathologySubmit={(p) =>
          setPathologyElements((prevState) => [...prevState, p])
        }
      />
      <AddPreviousTumorDialog
        open={openTumorModal}
        setOpen={setOpenTumorModal}
        selectedTumors={tumorElements}
        onTumorAdd={(tumor) =>
          setTumorElements((prevState) => [...prevState, tumor])
        }
      />
      <EditPreviousDiseasesDialog
        open={showPathologyModal}
        setOpen={setShowPathologyModal}
        pathology={
          selectedPathology >= 0
            ? pathologyElements[selectedPathology]
            : undefined
        }
        onMedicinesChanged={(medicines) => {
          if (selectedPathology >= 0) {
            setPathologyElements((prevState) =>
              prevState.map((p, i) => {
                if (i === selectedPathology) {
                  p.medicines = medicines;
                }
                return p;
              })
            );
          }
        }}
      />

      <EditPreviousTumorDialog
        open={showTumorModal}
        setOpen={setShowTumorModal}
        selectedTumor={
          selectedTumor >= 0 ? tumorElements[selectedTumor] : undefined
        }
      />
    </Paper>
  );
}
