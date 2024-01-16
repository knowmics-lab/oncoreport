/* eslint-disable @typescript-eslint/no-explicit-any */
// noinspection RequiredAttributes

import React, { useMemo, useState } from 'react';
import { Box, CircularProgress, FormGroup, Grid } from '@mui/material';
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
import SelectField from '../../../components/ui/Form/SelectField';
import TextField from '../../../components/ui/Form/TextField';
import { SubmitButton } from '../../../components/ui/Button';
import useRepositoryQuery from '../../../hooks/useRepositoryQuery';
import useNotifications from '../../../hooks/useNotifications';
import AutocompleteField from '../../../components/ui/Form/AutocompleteField';
import MultiSelectField from '../../../components/ui/Form/MultiSelectField';
import styles from '../../styles';

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
                      // TODO: fix this
                      // getOptionSelected={(option, value) => {
                      //   return option.id === value.id;
                      // }}
                      getOptionLabel={(option) =>
                        option && typeof option === 'object' && option.name
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
                <FormGroup row sx={styles.formControl}>
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
