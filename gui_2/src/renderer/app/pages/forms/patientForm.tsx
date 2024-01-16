/* eslint-disable @typescript-eslint/no-explicit-any */
// noinspection RequiredAttributes

import React, { useMemo, useState } from 'react';
import { useNavigate, useParams, generatePath } from 'react-router-dom';
import {
  CircularProgress,
  FormGroup,
  Grid,
  Icon,
  Paper,
  Typography,
} from '@mui/material';
import { Form, Formik } from 'formik';
import * as Yup from 'yup';
import dayjs from 'dayjs';
import { DiseaseRepository, PatientRepository } from '../../../../api';
import { Gender, TypeOfNotification } from '../../../../interfaces';
import SelectField from '../../components/ui/Form/SelectField';
import TextField from '../../components/ui/Form/TextField';
import Button, { SubmitButton } from '../../components/ui/Button';
import Routes from '../../../../constants/routes.json';
import { TumorTypes } from '../../../../interfaces/enums';
import useRepositoryFetchOneOrNew from '../../hooks/useRepositoryFetchOneOrNew';
import useNotifications from '../../hooks/useNotifications';
import AutocompleteField from '../../components/ui/Form/AutocompleteField';
import styles from '../styles';

function useValidationSchema() {
  return Yup.object().shape({
    code: Yup.string()
      .defined('Patient code is required')
      .max(255, 'Patient code is too long')
      .matches(/^[A-Za-z0-9_]+$/, {
        message: 'The field must contain only letters, numbers, and dashes.',
      }),
    first_name: Yup.string()
      .defined('First name is required')
      .max(255, 'First name is too long'),
    last_name: Yup.string()
      .defined('First name is required')
      .max(255, 'First name is too long'),
    age: Yup.number()
      .typeError('The age must be a number')
      .min(0, 'Age is too low')
      .max(100, 'Age is too high'),
    gender: Yup.mixed()
      .oneOf([Gender.m, Gender.f] as Gender[], 'Gender is invalid')
      .defined('Gender is required'),
    email: Yup.string()
      .required('The email is required')
      .nullable()
      .max(255, 'Email is too long')
      .email('Invalid email address'),
    fiscal_number: Yup.string()
      .notRequired()
      .nullable()
      .max(255, 'Fiscal Number is too long'),
    telephone: Yup.string()
      .notRequired()
      .nullable()
      .max(255, 'Telephone is too long'),
    city: Yup.string().notRequired().nullable().max(255, 'City is too long'),
    diagnosis_date: Yup.date().notRequired(),
    primary_disease: Yup.object({
      disease: Yup.object()
        .typeError('A valid disease is required')
        .defined('The disease is required')
        .required('The disease is required'),
      type: Yup.mixed()
        .oneOf([TumorTypes.primary, TumorTypes.secondary] as TumorTypes[])
        .notRequired()
        .nullable(),
      T: Yup.number().min(0).max(4).notRequired().nullable(),
      M: Yup.number().min(0).max(4).notRequired().nullable(),
      N: Yup.number().min(0).max(4).notRequired().nullable(),
    })
      .typeError('Please select a valid disease')
      .required('The disease is required'),
  });
}

export default function PatientForm() {
  const [submitting, setSubmitting] = useState(false);
  const history = useNavigate();
  const validationSchema = useValidationSchema();
  const { id } = useParams<{ id?: string }>();
  const { pushSimple } = useNotifications();

  const typeOptions = useMemo(
    () => ({
      [TumorTypes.primary]: 'Primary',
      [TumorTypes.secondary]: 'Secondary',
    }),
    [],
  );

  const [loadingPatient, patient] = useRepositoryFetchOneOrNew(
    PatientRepository,
    id ? +id : undefined,
  );

  const goBackUrl = useMemo(() => generatePath(Routes.PATIENTS), []);

  const initialValue = useMemo(() => {
    const d = patient?.toFormObject() ?? {};
    return {
      ...d,
      diagnosis_date:
        patient?.primary_disease?.start_date?.format?.('YYYY-MM-DD') ?? '',
    };
  }, [patient]);

  return (
    <Paper elevation={1} sx={styles.paperWithPadding}>
      {loadingPatient || !patient ? (
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
            initialValues={initialValue}
            validationSchema={validationSchema}
            onSubmit={async (d) => {
              try {
                setSubmitting(true);
                patient?.fill(d);
                if (patient && patient.primary_disease) {
                  patient.primary_disease.start_date = d.diagnosis_date
                    ? dayjs(d.diagnosis_date)
                    : dayjs();
                }
                await patient?.save();
                pushSimple('Patient saved!', TypeOfNotification.success);
                if (patient?.wasRecentlyCreated) {
                  history(generatePath(Routes.PATIENT, { id: patient.id }));
                } else {
                  history(goBackUrl);
                }
              } catch (e) {
                pushSimple(`An error occurred: ${e}`, TypeOfNotification.error);
                setSubmitting(false);
              }
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
                  <AutocompleteField
                    name="primary_disease.disease"
                    label="Primary Disease"
                    repositoryToken={DiseaseRepository}
                    queryBuilderCallback={(q) => q.paginate(100)}
                    parameters={{
                      tumor: true,
                    }}
                    // getOptionSelected={(option, value) => {
                    //   if (!option || !value) {
                    //     return false;
                    //   }
                    //   return option.id === value.id;
                    // }}
                    getOptionLabel={(option) => {
                      console.log(option);
                      return option && typeof option === 'object'
                        ? option.name
                        : 'Type something or Select a disease';
                    }}
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
                <Grid item md>
                  <TextField
                    label="Diagnosis Date"
                    name="diagnosis_date"
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
              <FormGroup row sx={styles.formControl}>
                <Grid container justifyContent="space-between">
                  <Grid item xs="auto">
                    <Button variant="contained" href={goBackUrl}>
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
