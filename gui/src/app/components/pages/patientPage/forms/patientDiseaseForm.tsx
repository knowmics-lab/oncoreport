/* eslint-disable @typescript-eslint/no-explicit-any */
// noinspection RequiredAttributes

import React, { useMemo, useState } from 'react';
import { createStyles, makeStyles } from '@material-ui/core/styles';
import { green } from '@material-ui/core/colors';
import { Box, CircularProgress, FormGroup, Grid } from '@material-ui/core';
import { Form, Formik } from 'formik';
import * as Yup from 'yup';
import dayjs from 'dayjs';
import {
  DiseaseRepository,
  LocationRepository,
  PatientDiseaseEntity,
  PatientEntity,
} from '../../../../../api';
import { SimpleMapArray, TypeOfNotification } from '../../../../../interfaces';
import SelectField from '../../../ui/Form/SelectField';
import TextField from '../../../ui/Form/TextField';
import { SubmitButton } from '../../../ui/Button';
import { TumorTypes } from '../../../../../interfaces/enums';
import useRepositoryQuery from '../../../../hooks/useRepositoryQuery';
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
    location: Yup.number().notRequired().nullable(),
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

  return (
    <Box margin={1}>
      {loadingLocations ? (
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
          <Formik
            initialValues={{
              ...disease.toFormObject(),
              disease: disease.disease,
            }}
            validationSchema={validationSchema}
            onSubmit={async (d) => {
              try {
                setSubmitting(true);
                /*
                {
                    T: d.T ? +d.T : undefined,
                    N: d.N ? +d.N : undefined,
                    M: d.M ? +d.M : undefined,
                    disease: +(d.disease?.id ?? 0),
                    end_date: d.end_date ? dayjs(d.end_date) : undefined,
                    location: d.location ? +d.location : undefined,
                    start_date: d.start_date ? dayjs(d.start_date) : dayjs(),
                    type: d.type,
                  }
                 */
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
                    {isTumor && (
                      <Grid item md>
                        <SelectField
                          name="location"
                          label="Site"
                          emptyText="Select a location"
                          addEmpty
                          options={locationOptions}
                        />
                      </Grid>
                    )}
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
        </>
      )}
    </Box>
  );
}

PatientDiseaseForm.defaultProps = {
  onSave: undefined,
};
