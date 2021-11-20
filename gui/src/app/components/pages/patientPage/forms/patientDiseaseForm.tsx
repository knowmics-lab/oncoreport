/* eslint-disable @typescript-eslint/no-explicit-any */
// noinspection RequiredAttributes

import React, { useMemo, useState } from 'react';
import { createStyles, makeStyles } from '@material-ui/core/styles';
import { green } from '@material-ui/core/colors';
import { Box, FormGroup, Grid } from '@material-ui/core';
import { Form, Formik } from 'formik';
import * as Yup from 'yup';
import dayjs from 'dayjs';
import {
  DiseaseRepository,
  PatientDiseaseEntity,
  PatientEntity,
} from '../../../../../api';
import { TypeOfNotification } from '../../../../../interfaces';
import SelectField from '../../../ui/Form/SelectField';
import TextField from '../../../ui/Form/TextField';
import { SubmitButton } from '../../../ui/Button';
import { TumorTypes } from '../../../../../interfaces/enums';
import useNotifications from '../../../../hooks/useNotifications';
import AutocompleteField from '../../../ui/Form/AutocompleteField';

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
    disease: Yup.object().defined(),
    type: Yup.mixed()
      .oneOf([TumorTypes.primary, TumorTypes.secondary] as TumorTypes[])
      .notRequired()
      .nullable(),
    T: Yup.number().min(0).max(4).notRequired().nullable(),
    M: Yup.number().min(0).max(4).notRequired().nullable(),
    N: Yup.number().min(0).max(4).notRequired().nullable(),
    start_date: Yup.date().notRequired(),
    end_date: Yup.date().notRequired(),
  });
}

type Props = {
  disease: PatientDiseaseEntity;
  patient: PatientEntity;
  onSave?: () => void;
};

export default function PatientDiseaseForm({
  disease,
  patient,
  onSave,
}: Props) {
  const classes = useStyles();
  const isPrimary = disease.id === patient.primary_disease.id;
  const [submitting, setSubmitting] = useState(false);
  const validationSchema = useValidationSchema();
  const { pushSimple } = useNotifications();

  const typeOptions = useMemo(
    () => ({
      [TumorTypes.primary]: 'Primary',
      [TumorTypes.secondary]: 'Secondary',
    }),
    []
  );

  return (
    <Box margin={1}>
      <Formik
        initialValues={{
          ...disease.toFormObject(),
          disease: disease.disease,
        }}
        validationSchema={validationSchema}
        onSubmit={async (d) => {
          try {
            setSubmitting(true);
            await disease
              .fill({
                ...d,
                start_date: d.start_date ? dayjs(d.start_date) : dayjs(),
                end_date: d.end_date ? dayjs(d.end_date) : undefined,
              })
              .save();
            setSubmitting(false);
            pushSimple('Disease saved!', TypeOfNotification.success);
            if (onSave) onSave();
          } catch (e) {
            pushSimple(`An error occurred: ${e}`, TypeOfNotification.error);
            setSubmitting(false);
          }
        }}
      >
        {({ values }) => {
          const isTumor = !!values?.disease?.tumor;
          return (
            <Form>
              <Grid container spacing={2}>
                <Grid item md>
                  <AutocompleteField
                    name="disease"
                    label="Disease"
                    repositoryToken={DiseaseRepository}
                    queryBuilderCallback={(q) => q.paginate(50)}
                    parameters={{
                      tumor: isPrimary,
                    }}
                    getOptionSelected={(option, value) => {
                      return option.id === value.id;
                    }}
                    getOptionLabel={(option) =>
                      option ? option.name : 'Select a disease'
                    }
                  />
                </Grid>
                {isTumor && (
                  <Grid item md>
                    <SelectField
                      name="type"
                      label="Disease type"
                      emptyText="Not Available"
                      addEmpty
                      options={typeOptions}
                    />
                  </Grid>
                )}
              </Grid>
              <Grid container spacing={2}>
                <Grid item md>
                  <TextField
                    label="Diagnosis Date"
                    name="start_date"
                    type="date"
                    InputLabelProps={{
                      shrink: true,
                    }}
                  />
                </Grid>
                {!isPrimary && (
                  <Grid item md>
                    <TextField
                      label="Remission Date"
                      name="end_date"
                      type="date"
                      InputLabelProps={{
                        shrink: true,
                      }}
                    />
                  </Grid>
                )}
              </Grid>
              {isTumor && (
                <Grid container spacing={2}>
                  <Grid item md>
                    <SelectField
                      name="T"
                      label="T"
                      emptyText="Not Available"
                      addEmpty
                      options={['0', '1', '2', '3', '4']}
                    />
                  </Grid>
                  <Grid item md>
                    <SelectField
                      name="N"
                      label="N"
                      emptyText="Not Available"
                      addEmpty
                      options={['0', '1', '2', '3']}
                    />
                  </Grid>
                  <Grid item md>
                    <SelectField
                      name="M"
                      label="M"
                      emptyText="Not Available"
                      addEmpty
                      options={['0', '1']}
                    />
                  </Grid>
                </Grid>
              )}
              <FormGroup row className={classes.formControl}>
                <Grid container justifyContent="flex-end">
                  <Grid item xs="auto">
                    <SubmitButton text="Save" isSaving={submitting} />
                  </Grid>
                </Grid>
              </FormGroup>
            </Form>
          );
        }}
      </Formik>
    </Box>
  );
}

PatientDiseaseForm.defaultProps = {
  onSave: undefined,
};
