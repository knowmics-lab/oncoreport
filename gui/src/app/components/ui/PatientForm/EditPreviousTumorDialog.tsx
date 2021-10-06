import React from 'react';
import Dialog from '@material-ui/core/Dialog';
import DialogTitle from '@material-ui/core/DialogTitle';
import { Field, Form, Formik } from 'formik';
import {
  DialogActions,
  DialogContent,
  DialogContentText,
  Grid,
} from '@material-ui/core';
import * as Yup from 'yup';
import { Autocomplete } from '@material-ui/lab';
import Chip from '@material-ui/core/Chip';
import { FormikSelect } from '../Form/FormikSelect';
import { Nullable, Option, Resource } from '../../../../interfaces';
import Button, { SubmitButton } from '../Button';
import SelectField from '../Form/SelectField';
import { Tumor } from '../../../../interfaces/entities/tumor';
import { DrugRepository, LocationRepository } from '../../../../api';
import useRepositoryFetch from '../../../hooks/useRepositoryFetch';
import TextField from '../Form/TextField';
import { Drug } from '../../../../interfaces/entities/drug';

interface Props {
  open: boolean;
  setOpen: (isOpen: boolean) => void;
  selectedTumor: Nullable<Tumor>;
}

interface FormContent {
  drugs: (Resource | Drug)[];
  sede: Resource;
  type: string;
  T: number;
  N: number;
  M: number;
}

function useValidationSchema() {
  return Yup.object().shape({
    sede: Yup.object().required(),
    type: Yup.mixed().oneOf(['primary', 'secondary']),
    T: Yup.number().min(0).max(4),
    M: Yup.number().min(0).max(4),
    N: Yup.number().min(0).max(4),
  });
}

export default function EditPreviousTumorDialog({
  open,
  setOpen,
  selectedTumor,
}: Props) {
  const validationSchema = useValidationSchema();
  const [loadingDrugs, drugs] = useRepositoryFetch(
    DrugRepository,
    (r) => ({ value: r, label: r.name } as Option)
  );
  const [loadingLocations, locations] = useRepositoryFetch(
    LocationRepository,
    (r) => ({ value: r, label: r.name } as Option)
  );
  const closeModal = () => setOpen(false);

  return (
    <>
      {selectedTumor && (
        <Dialog
          open={open}
          onClose={closeModal}
          aria-labelledby="form-dialog-title"
        >
          <DialogTitle id="form-dialog-title">
            Edit {selectedTumor.name}
          </DialogTitle>
          <Formik<FormContent>
            validationSchema={validationSchema}
            initialValues={{
              drugs: selectedTumor.drugs,
              type: selectedTumor.type ?? '',
              sede: selectedTumor.sede[0],
              T: selectedTumor.stadio?.T ?? 0,
              N: selectedTumor.stadio?.N ?? 0,
              M: selectedTumor.stadio?.M ?? 0,
            }}
            onSubmit={(d) => {
              if (selectedTumor) {
                selectedTumor.type = d.type;
                selectedTumor.sede = [d.sede];
                selectedTumor.drugs = d.drugs;
                selectedTumor.stadio = {
                  T: d.T,
                  N: d.N,
                  M: d.M,
                };
              }
              closeModal();
            }}
          >
            {({ values, setFieldValue }) => {
              const selectedDrugIds = values.drugs.map((d) => d.id);
              const selectedDrugs = values.drugs.map(
                (d) =>
                  ({
                    value: d,
                    label: d.name,
                  } as Option)
              );
              return (
                <Form>
                  <DialogContent>
                    <DialogContentText>Details</DialogContentText>
                    <Grid container spacing={4}>
                      <Grid item md>
                        <SelectField
                          name="type"
                          label="Type"
                          emptyText="Select a type"
                          options={{
                            primary: 'Primary tumor',
                            secondary: 'Secondary tumor',
                          }}
                        />
                      </Grid>
                      <Grid item md>
                        <Field
                          name="sede"
                          label="Location"
                          component={FormikSelect}
                          options={locations}
                          loading={loadingLocations}
                        />
                      </Grid>
                    </Grid>

                    <DialogContentText>TMN staging:</DialogContentText>
                    <Grid container spacing={3}>
                      <Grid item md>
                        <SelectField
                          name="T"
                          label="T"
                          options={['0', '1', '2', '3']}
                        />
                      </Grid>
                      <Grid item md>
                        <SelectField
                          name="N"
                          label="N"
                          options={['0', '1', '2', '3']}
                        />
                      </Grid>
                      <Grid item md>
                        <SelectField
                          name="M"
                          label="M"
                          options={['0', '1', '2', '3']}
                        />
                      </Grid>
                    </Grid>
                    <DialogContentText>Select used drugs</DialogContentText>
                    <Autocomplete
                      loading={loadingDrugs}
                      options={drugs}
                      getOptionLabel={(option) => option.label}
                      getOptionSelected={(o1, o2) => {
                        return o1.value.id === o2.value.id;
                      }}
                      value={selectedDrugs}
                      getOptionDisabled={(option: Option) =>
                        selectedDrugIds.includes(option.value.id)
                      }
                      autoComplete
                      autoHighlight
                      multiple
                      onChange={(_e, value) => {
                        setFieldValue(
                          'drugs',
                          value.map((v) => v.value)
                        );
                      }}
                      renderInput={(params) => (
                        <TextField
                          {...params}
                          name="drugs"
                          variant="outlined"
                        />
                      )}
                      renderTags={(tagValue, getTagProps) =>
                        tagValue.map((option, index) => {
                          const isDisabled =
                            // eslint-disable-next-line no-prototype-builtins
                            option.value.hasOwnProperty('end_date') &&
                            // eslint-disable-next-line @typescript-eslint/ban-ts-comment
                            // @ts-ignore
                            !!option.value.end_date;
                          return (
                            <Chip
                              key={option.value.id}
                              label={option.label}
                              {...getTagProps({ index })}
                              disabled={isDisabled}
                            />
                          );
                        })
                      }
                    />
                  </DialogContent>
                  <DialogActions>
                    <Button onClick={closeModal} color="primary">
                      Cancel
                    </Button>
                    <SubmitButton isSaving={false} text="Save" />
                  </DialogActions>
                </Form>
              );
            }}
          </Formik>
        </Dialog>
      )}
    </>
  );
}
