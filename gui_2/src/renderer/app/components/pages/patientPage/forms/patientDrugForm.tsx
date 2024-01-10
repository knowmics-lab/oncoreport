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
  DrugEntity,
  DrugRepository,
  PatientDiseaseRepository,
  PatientDrugEntity,
  PatientEntity,
  SuspensionReasonRepository,
} from '../../../../../api';
import { SimpleMapArray, TypeOfNotification } from '../../../../../interfaces';
import SelectField from '../../../ui/Form/SelectField';
import TextField from '../../../ui/Form/TextField';
import { SubmitButton } from '../../../ui/Button';
import useRepositoryQuery from '../../../../hooks/useRepositoryQuery';
import useNotifications from '../../../../hooks/useNotifications';
import AutocompleteField from '../../../ui/Form/AutocompleteField';
import MultiSelectField from '../../../ui/Form/MultiSelectField';

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
  }),
);

function useValidationSchema() {
  return Yup.object().shape({
    drug: Yup.object().defined(),
    disease: Yup.number().notRequired(),
    suspension_reasons: Yup.array().of(Yup.number()).nullable(),
    comment: Yup.string().notRequired().nullable(),
    start_date: Yup.date().notRequired(),
    end_date: Yup.date().notRequired(),
  });
}

type Props = {
  drug: PatientDrugEntity;
  patient: PatientEntity;
  onSave?: () => void;
};

export default function PatientDrugForm({ drug, patient, onSave }: Props) {
  const classes = useStyles();
  const [submitting, setSubmitting] = useState(false);
  const validationSchema = useValidationSchema();
  const { pushSimple } = useNotifications();

  const [loadingDiseases, diseases] = useRepositoryQuery(
    PatientDiseaseRepository,
    (builder) => builder.doNotPaginate(),
    {
      patient_id: patient.id,
    },
  );
  const diseasesOptions = useMemo(() => {
    if (loadingDiseases || !diseases) return {};
    return diseases.reduce((prev: SimpleMapArray<string>, d) => {
      prev[d.id] = `${d.disease?.name} of ${d.start_date.format('YYYY-MM-DD')}`;
      return prev;
    }, {});
  }, [loadingDiseases, diseases]);

  const [loadingSuspensionReasons, suspensionReasons] = useRepositoryQuery(
    SuspensionReasonRepository,
    (builder) => builder.doNotPaginate(),
  );
  const suspensionReasonsOptions = useMemo(() => {
    if (loadingSuspensionReasons || !suspensionReasons) return [];
    return suspensionReasons.map((v) => ({
      label: v.name,
      value: v.id,
    }));
  }, [loadingSuspensionReasons, suspensionReasons]);

  const loading = loadingSuspensionReasons || loadingDiseases;

  return (
    <Box margin={1}>
      {loading ? (
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
        <Formik
          initialValues={{
            ...drug.toFormObject(),
            drug: (drug.drug ?? {}) as unknown as DrugEntity,
          }}
          validationSchema={validationSchema}
          onSubmit={async (d) => {
            try {
              setSubmitting(true);
              await drug
                .fill({
                  ...d,
                  start_date: d.start_date ? dayjs(d.start_date) : dayjs(),
                  end_date: d.end_date ? dayjs(d.end_date) : undefined,
                  // drug: +(d.drug?.id ?? 0),
                  // disease: d.disease ? +d.disease : undefined,
                  // suspension_reasons: d.suspension_reasons
                  //   ? d.suspension_reasons
                  //   : undefined,
                  // comment:
                  //   d.comment && `${d.comment}`.trim().length > 0
                  //     ? `${d.comment}`.trim()
                  //     : undefined,
                })
                .save();
              setSubmitting(false);
              pushSimple('Drug saved!', TypeOfNotification.success);
              if (onSave) onSave();
            } catch (e) {
              pushSimple(`An error occurred: ${e}`, TypeOfNotification.error);
              setSubmitting(false);
            }
          }}
        >
          {({ values }) => {
            const isSuspended =
              values.end_date && dayjs(values.end_date).isValid();
            return (
              <Form>
                <Grid container spacing={2}>
                  <Grid item md>
                    <AutocompleteField
                      name="drug"
                      label="Drug"
                      repositoryToken={DrugRepository}
                      queryBuilderCallback={(q) => q.paginate(50)}
                      getOptionSelected={(option, value) => {
                        return option.id === value.id;
                      }}
                      getOptionLabel={(option) =>
                        option && option.name
                          ? `${option.drugbank_id} - ${option.name}`
                          : 'Select a drug'
                      }
                    />
                  </Grid>
                  <Grid item md>
                    <SelectField
                      name="disease"
                      label="Disease"
                      emptyText="Not Available"
                      addEmpty
                      options={diseasesOptions}
                    />
                  </Grid>
                </Grid>
                <Grid container spacing={2}>
                  <Grid item md>
                    <TextField
                      label="Start Date"
                      name="start_date"
                      type="date"
                      InputLabelProps={{
                        shrink: true,
                      }}
                    />
                  </Grid>
                  <Grid item md>
                    <TextField
                      label="Suspension Date"
                      name="end_date"
                      type="date"
                      InputLabelProps={{
                        shrink: true,
                      }}
                    />
                  </Grid>
                </Grid>
                <Grid container spacing={2}>
                  {isSuspended && (
                    <>
                      <Grid item md>
                        <MultiSelectField<number>
                          name="suspension_reasons"
                          label="Suspension reasons"
                          options={suspensionReasonsOptions}
                        />
                      </Grid>
                      <Grid item md>
                        <TextField
                          label="Comments"
                          name="comment"
                          type="text"
                          multiline
                          InputLabelProps={{
                            shrink: true,
                          }}
                        />
                      </Grid>
                    </>
                  )}
                </Grid>
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
      )}
    </Box>
  );
}

PatientDrugForm.defaultProps = {
  onSave: undefined,
};
