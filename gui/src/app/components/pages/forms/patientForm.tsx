/* eslint-disable @typescript-eslint/no-explicit-any */
import React, { useMemo, useState } from 'react';
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
import dayjs from 'dayjs';
import {
  DiseaseRepository,
  PatientRepository,
  LocationRepository,
} from '../../../../api';
import {
  Gender,
  SimpleMapArray,
  TypeOfNotification,
} from '../../../../interfaces';
import SelectField from '../../ui/Form/SelectField';
import TextField from '../../ui/Form/TextField';
import Button, { SubmitButton } from '../../ui/Button';
import Routes from '../../../../constants/routes.json';
import { TumorTypes } from '../../../../interfaces/enums';
import useRepositoryQuery from '../../../hooks/useRepositoryQuery';
import useRepositoryFetchOneOrNew from '../../../hooks/useRepositoryFetchOneOrNew';
import useNotifications from '../../../hooks/useNotifications';

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
    email: Yup.string().notRequired().nullable().max(255).email(),
    fiscal_number: Yup.string().notRequired().nullable().max(255),
    telephone: Yup.string().notRequired().nullable().max(255),
    city: Yup.string().notRequired().nullable().max(255),
    primary_disease: Yup.object().shape({
      disease: Yup.number().defined(),
      location: Yup.number().notRequired().nullable(),
      type: Yup.mixed()
        .oneOf([TumorTypes.primary, TumorTypes.secondary] as TumorTypes[])
        .notRequired()
        .nullable(),
      T: Yup.number().min(0).max(4).notRequired().nullable(),
      M: Yup.number().min(0).max(4).notRequired().nullable(),
      N: Yup.number().min(0).max(4).notRequired().nullable(),
      start_date: Yup.date().notRequired(),
    }),
  });
}

export default function PatientForm() {
  const classes = useStyles();
  const [submitting, setSubmitting] = useState(false);
  const history = useHistory();
  const validationSchema = useValidationSchema();
  const { id } = useParams<{ id?: string }>();
  const { pushSimple } = useNotifications();

  const [loadingDiseases, diseases] = useRepositoryQuery(
    DiseaseRepository,
    (builder) => builder.doNotPaginate(),
    {
      tumor: true,
    }
  );
  const diseaseOptions = useMemo(() => {
    if (loadingDiseases || !diseases) return {};
    return diseases.reduce((prev: SimpleMapArray<string>, location) => {
      prev[location.id] = location.name;
      return prev;
    }, {});
  }, [diseases, loadingDiseases]);

  const [loadingLocations, locations] = useRepositoryQuery(
    LocationRepository,
    (builder) => builder.doNotPaginate()
  );
  const locationOptions = useMemo(() => {
    if (loadingLocations || !locations) return {};
    return locations.reduce((prev: SimpleMapArray<string>, location) => {
      prev[location.id] = location.name;
      return prev;
    }, {});
  }, [loadingLocations, locations]);

  const typeOptions = useMemo(
    () => ({
      [TumorTypes.primary]: 'Primary',
      [TumorTypes.secondary]: 'Secondary',
    }),
    []
  );

  const [loadingPatient, patient] = useRepositoryFetchOneOrNew(
    PatientRepository,
    id ? +id : undefined
  );

  const loading = loadingPatient || loadingLocations || loadingDiseases;

  const goBackUrl = useMemo(() => generatePath(Routes.PATIENTS), []);

  return (
    <Paper elevation={1} className={classes.paper}>
      {loading || !patient ? (
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
          <Typography variant="h5" component="h3">
            {patient.isNew ? 'New Patient' : 'Edit Patient'}
          </Typography>
          <Formik
            initialValues={patient.toFormObject()}
            validationSchema={validationSchema}
            onSubmit={async (d) => {
              try {
                setSubmitting(true);
                const primaryDisease = d.primary_disease as unknown as Record<
                  string,
                  any
                >;
                const cleanedData = {
                  code: d.code,
                  first_name: d.first_name,
                  last_name: d.last_name,
                  age: d.age ? +d.age : undefined,
                  gender: d.gender,
                  email: d.email,
                  fiscal_number: d.fiscal_number,
                  telephone: d.telephone,
                  city: d.city,
                  primary_disease: {
                    T: primaryDisease.T ? +primaryDisease.T : undefined,
                    N: primaryDisease.N ? +primaryDisease.N : undefined,
                    M: primaryDisease.M ? +primaryDisease.M : undefined,
                    disease: +primaryDisease.disease,
                    end_date: undefined,
                    location: primaryDisease.location
                      ? +primaryDisease.location
                      : undefined,
                    start_date: primaryDisease.start_date
                      ? dayjs(primaryDisease.start_date)
                      : dayjs(),
                    type: primaryDisease.type,
                  },
                };
                await patient?.fill(cleanedData).save();
                pushSimple('Patient saved!', TypeOfNotification.success);
                if (patient?.wasRecentlyCreated) {
                  history.push(
                    generatePath(Routes.PATIENT, { id: patient.id })
                  );
                } else {
                  history.push(goBackUrl);
                }
              } catch (e) {
                pushSimple(`An error occurred: ${e}`, TypeOfNotification.error);
                setSubmitting(false);
              }
              // setSubmitting(false);
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
                    addEmpty
                    options={{
                      [Gender.m]: 'Male',
                      [Gender.f]: 'Female',
                    }}
                    required
                  />
                </Grid>
              </Grid>
              <TextField label="Fiscal Number" name="fiscal_number" />
              <Grid container spacing={2}>
                <Grid item md>
                  <TextField label="Email" name="email" type="email" required />
                </Grid>
                <Grid item md>
                  <TextField label="Telephone" name="telephone" type="string" />
                </Grid>
                <Grid item md>
                  <TextField label="City" name="city" />
                </Grid>
              </Grid>
              <Grid container spacing={2}>
                <Grid item md>
                  <SelectField
                    name="primary_disease.disease"
                    label="Primary Disease"
                    required
                    emptyText="Select a disease"
                    addEmpty
                    options={diseaseOptions}
                  />
                </Grid>
                <Grid item md>
                  <SelectField
                    name="primary_disease.type"
                    label="Disease type"
                    emptyText="Not Available"
                    addEmpty
                    options={typeOptions}
                  />
                </Grid>
              </Grid>
              <Grid container spacing={2}>
                <Grid item md>
                  <SelectField
                    name="primary_disease.location"
                    label="Site"
                    emptyText="Select a location"
                    addEmpty
                    options={locationOptions}
                  />
                </Grid>
                <Grid item md>
                  <TextField
                    label="Diagnosis Date"
                    name="primary_disease.start_date"
                    type="date"
                    InputLabelProps={{
                      shrink: true,
                    }}
                  />
                </Grid>
              </Grid>
              <Grid container spacing={2}>
                <Grid item md>
                  <SelectField
                    name="primary_disease.T"
                    label="T"
                    emptyText="Not Available"
                    addEmpty
                    options={['0', '1', '2', '3', '4']}
                  />
                </Grid>
                <Grid item md>
                  <SelectField
                    name="primary_disease.N"
                    label="N"
                    emptyText="Not Available"
                    addEmpty
                    options={['0', '1', '2', '3']}
                  />
                </Grid>
                <Grid item md>
                  <SelectField
                    name="primary_disease.M"
                    label="M"
                    emptyText="Not Available"
                    addEmpty
                    options={['0', '1']}
                  />
                </Grid>
              </Grid>
              <FormGroup row className={classes.formControl}>
                <Grid container justifyContent="space-between">
                  <Grid item xs="auto">
                    <Button
                      variant="contained"
                      color="default"
                      href={goBackUrl}
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
        </>
      )}
    </Paper>
  );
}
