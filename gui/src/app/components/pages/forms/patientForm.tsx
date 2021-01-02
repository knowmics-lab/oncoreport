import React, { useEffect, useMemo, useState } from 'react';
import { useHistory, useParams } from 'react-router-dom';
import { createStyles, makeStyles } from '@material-ui/core/styles';
import { green } from '@material-ui/core/colors';
import {
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
import SelectField from '../../UI/Form/SelectField';
import TextField from '../../UI/Form/TextField';
import Button, { SubmitButton } from '../../UI/Button';
import Routes from '../../../../constants/routes.json';

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
  const [patient, setPatient] = useState<MaybePatient>();
  const [submitting, setSubmitting] = useState(false);
  const history = useHistory();
  const { id } = useParams<{ id?: string }>();

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
      setLoading(true);
      if (id) {
        setPatient(await (await repository.fetch(+id)).refresh());
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
                return runAsync(async (manager) => {
                  setSubmitting(true);
                  await patient?.fill(d).save();
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
    </Paper>
  );
}
