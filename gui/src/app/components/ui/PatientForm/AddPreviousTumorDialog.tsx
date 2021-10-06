import React, { useMemo } from 'react';
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
import { FormikSelect } from '../Form/FormikSelect';
import { Nullable, Option, Resource } from '../../../../interfaces';
import Button, { SubmitButton } from '../Button';
import SelectField from '../Form/SelectField';
import { Tumor } from '../../../../interfaces/entities/tumor';
import {
  DrugRepository,
  TumorRepository,
  LocationRepository,
} from '../../../../api';
import useRepositoryFetch from '../../../hooks/useRepositoryFetch';

interface Props {
  open: boolean;
  setOpen: (isOpen: boolean) => void;
  selectedTumors: Tumor[];
  onTumorAdd: (tumor: Tumor) => void;
}

interface FormContent {
  tumor: Nullable<Resource>;
  drugs: Resource[];
  sede: Nullable<Resource>;
  type: string;
  T: number;
  N: number;
  M: number;
}

function useValidationSchema() {
  return Yup.object().shape({
    tumor: Yup.object().required(),
    sede: Yup.object().required(),
    type: Yup.mixed().oneOf(['primary', 'secondary']),
    T: Yup.number().min(0).max(4),
    M: Yup.number().min(0).max(4),
    N: Yup.number().min(0).max(4),
  });
}

export default function AddPreviousTumorDialog({
  open,
  setOpen,
  selectedTumors,
  onTumorAdd,
}: Props) {
  const validationSchema = useValidationSchema();
  const [loadingTumors, tumors] = useRepositoryFetch(
    TumorRepository,
    (r) => ({ value: r, label: r.name } as Option)
  );
  const [loadingDrugs, drugs] = useRepositoryFetch(
    DrugRepository,
    (r) => ({ value: r, label: r.name } as Option)
  );
  const [loadingLocations, locations] = useRepositoryFetch(
    LocationRepository,
    (r) => ({ value: r, label: r.name } as Option)
  );
  const selectedTumorIds = useMemo(
    () => selectedTumors.map((t) => t.id),
    [selectedTumors]
  );
  const closeModal = () => setOpen(false);

  return (
    <>
      <Dialog
        open={open}
        onClose={closeModal}
        aria-labelledby="form-dialog-title"
      >
        <DialogTitle id="form-dialog-title">Add tumor</DialogTitle>
        <Formik<FormContent>
          validationSchema={validationSchema}
          initialValues={{
            tumor: null,
            drugs: [],
            sede: null,
            type: '',
            T: 0,
            N: 0,
            M: 0,
          }}
          onSubmit={(d) => {
            if (d.tumor && d.sede) {
              onTumorAdd({
                id: d.tumor.id,
                name: d.tumor.name,
                type: d.type,
                drugs: d.drugs,
                sede: [d.sede],
                stadio: {
                  T: d.T,
                  N: d.N,
                  M: d.M,
                },
              });
            }
            closeModal();
          }}
        >
          <Form>
            <DialogContent>
              <DialogContentText>Select the tumor disease</DialogContentText>
              <Field
                name="tumor"
                component={FormikSelect}
                options={tumors}
                loading={loadingTumors}
                getOptionDisabled={(option: Option) =>
                  selectedTumorIds.includes(option.value.id)
                }
              />
              <DialogContentText>Other details</DialogContentText>
              <Grid container spacing={4}>
                <Grid item md>
                  <SelectField
                    name="type"
                    emptyText="Select a type"
                    addEmpty
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
                    emptyText="T"
                    addEmpty
                    options={['0', '1', '2', '3']}
                  />
                </Grid>
                <Grid item md>
                  <SelectField
                    name="N"
                    label="N"
                    emptyText="N"
                    addEmpty
                    options={['0', '1', '2', '3']}
                  />
                </Grid>
                <Grid item md>
                  <SelectField
                    name="M"
                    label="M"
                    emptyText="M"
                    addEmpty
                    options={['0', '1', '2', '3']}
                  />
                </Grid>
              </Grid>

              <DialogContentText>Select used drugs</DialogContentText>
              <Field
                name="drugs"
                isMulti
                component={FormikSelect}
                options={drugs}
                loading={loadingDrugs}
              />
            </DialogContent>
            <DialogActions>
              <Button onClick={closeModal} color="primary">
                Cancel
              </Button>
              <SubmitButton isSaving={false} text="Confirm" />
            </DialogActions>
          </Form>
        </Formik>
      </Dialog>
    </>
  );
}
