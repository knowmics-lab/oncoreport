import React, { useCallback, useEffect, useState } from 'react';
import Dialog from '@material-ui/core/Dialog';
import DialogTitle from '@material-ui/core/DialogTitle';
import {
  DialogActions,
  DialogContent,
  DialogContentText,
  TextField,
} from '@material-ui/core';
import { Autocomplete } from '@material-ui/lab';
import { Nullable, Option, Resource } from '../../../../interfaces';
import Button from '../Button';
import { Pathology } from '../../../../interfaces/entities/pathology';
import { MedicineRepository } from '../../../../api';
import useRepositoryFetch from '../../../hooks/useRepositoryFetch';

interface Props {
  open: boolean;
  setOpen: (isOpen: boolean) => void;
  pathology: Nullable<Pathology>;
  onMedicinesChanged: (medicines: Resource[]) => void;
}

export default function EditPreviousDiseasesDialog({
  open,
  setOpen,
  pathology,
  onMedicinesChanged,
}: Props) {
  const [selection, setSelection] = useState<{
    ids: number[];
    options: Option[];
  }>({ ids: [], options: [] });

  const refreshSelection = useCallback(() => {
    if (pathology) {
      const ids = pathology.medicines.map((m) => m.id);
      const options = pathology.medicines.map(
        (m) =>
          ({
            value: m,
            label: m.name ?? '',
          } as Option)
      );
      setSelection({ ids, options });
    }
  }, [pathology]);

  useEffect(() => {
    refreshSelection();
  }, [pathology, refreshSelection]);

  const [loadingMedicines, medicines] = useRepositoryFetch(
    MedicineRepository,
    (r) => ({ value: r, label: r.name } as Option)
  );
  const closeModal = () => {
    setOpen(false);
  };

  return (
    <>
      {pathology && (
        <Dialog open={open} onClose={closeModal}>
          <DialogTitle>Add treatments to {pathology.name}</DialogTitle>
          <DialogContent>
            <DialogContentText>Select the applied therapy</DialogContentText>
            <Autocomplete
              id="combo-box-demo"
              options={medicines}
              loading={loadingMedicines}
              value={selection.options}
              getOptionLabel={(option) => option.label ?? ''}
              getOptionSelected={(option, value) => {
                return option.value.id === value.value.id;
              }}
              getOptionDisabled={(option: Option) =>
                selection.ids.includes(option.value.id)
              }
              autoComplete
              autoHighlight
              multiple
              onChange={(_e, value) => {
                onMedicinesChanged(value.map((v) => v.value));
                refreshSelection();
              }}
              renderInput={(params) => (
                <TextField {...params} variant="outlined" />
              )}
            />
          </DialogContent>
          <DialogActions>
            <Button onClick={closeModal} color="primary">
              Close
            </Button>
          </DialogActions>
        </Dialog>
      )}
    </>
  );
}
