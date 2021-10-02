import React, { useMemo } from 'react';
import Dialog from '@material-ui/core/Dialog';
import DialogTitle from '@material-ui/core/DialogTitle';
import { Field, Form, Formik } from 'formik';
import {
  DialogActions,
  DialogContent,
  DialogContentText,
} from '@material-ui/core';
import { FormikSelect } from '../Form/FormikSelect';
import { Option, Resource } from '../../../../interfaces';
import Button, { SubmitButton } from '../Button';
import { Pathology } from '../../../../interfaces/entities/pathology';
import { MedicineRepository, PathologyRepository } from '../../../../api';
import useRepositoryFetch from '../../../hooks/useRepositoryFetch';

interface Props {
  open: boolean;
  setOpen: (isOpen: boolean) => void;
  selectedPathologies: Pathology[];
  onPathologySubmit: (pathology: Pathology) => void;
}

interface FormContent {
  pathology?: Resource;
  medicines: Resource[];
}

export default function AddPreviousDiseasesDialog({
  open,
  setOpen,
  selectedPathologies,
  onPathologySubmit,
}: Props) {
  const selectedPathologiesIds = useMemo(
    () => selectedPathologies.map((p) => p.id),
    [selectedPathologies]
  );
  const [loadingPathologies, pathologies] = useRepositoryFetch(
    PathologyRepository,
    (r) => ({ value: r, label: r.name } as Option)
  );
  const [loadingMedicines, medicines] = useRepositoryFetch(
    MedicineRepository,
    (r) => ({ value: r, label: r.name } as Option)
  );
  const loading = loadingPathologies || loadingMedicines;
  const closeModal = () => setOpen(false);

  return (
    <>
      <Dialog open={open} onClose={closeModal}>
        <DialogTitle>Add previous disease</DialogTitle>
        <Formik<FormContent>
          initialValues={{ pathology: undefined, medicines: [] }}
          onSubmit={(d) => {
            if (d.pathology) {
              onPathologySubmit({
                id: d.pathology.id,
                name: d.pathology.name,
                medicines: d.medicines,
              });
            }
            setOpen(false);
          }}
        >
          <Form>
            <DialogContent style={{ minWidth: 600 }}>
              <DialogContentText>Select a disease</DialogContentText>
              <Field
                name="pathology"
                component={FormikSelect}
                options={pathologies}
                loading={loading}
                getOptionDisabled={(option: Option) =>
                  selectedPathologiesIds.includes(option.value.id)
                }
              />
              <DialogContentText>Select the applied therapy</DialogContentText>
              <Field
                name="medicines"
                isMulti
                component={FormikSelect}
                options={medicines}
                loading={loading}
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
