/* eslint-disable @typescript-eslint/no-explicit-any */
import {
  Dialog,
  DialogActions,
  DialogContent,
  DialogContentText,
  DialogTitle,
  IconButton,
} from '@material-ui/core';
import { Field, Form, Formik } from 'formik';
import React, { useCallback, useMemo, useState } from 'react';
import PauseCircleFilledRoundedIcon from '@material-ui/icons/PauseCircleFilledRounded';
import Button, { SubmitButton } from '../ui/Button';
import { FormikSelect } from '../ui/Form/FormikSelect';
import CollapsibleTable from '../ui/Table/CollipsableTable';
import TextField from '../ui/Form/TextField';
import Connector from '../../../api/adapters/connector';
import { useService } from '../../../reactInjector';
import { PatientEntity, ResourceEntity } from '../../../api';
import { Drug } from '../../../interfaces/entities/drug';

type DialogData = undefined | { index: number; drug: Drug; tumor: any };
interface ReasonDialogProps {
  onSubmit: (
    drugId: number,
    tumorId: number,
    reasons: number[],
    comment: string,
    setSubmitting: (state: boolean) => void
  ) => void;
  dialogData: DialogData;
  setDialogData: (data: DialogData) => void;
  availableReasons: ResourceEntity[];
}

function ReasonDialog({
  onSubmit,
  dialogData,
  setDialogData,
  availableReasons,
}: ReasonDialogProps) {
  const [submitting, setSubmitting] = useState<boolean>(false);
  const onClose = useCallback(() => setDialogData(undefined), [setDialogData]);
  const otherReasons = useMemo(
    () =>
      availableReasons
        .filter((r) => r.name.toLowerCase().startsWith('other'))
        .map((r) => r.id),
    [availableReasons]
  );
  return (
    <Dialog open={!!dialogData} onClose={onClose}>
      <DialogTitle>Suspension reasons for {dialogData?.drug.name}</DialogTitle>
      <Formik<{ reasons: number[]; comment: string }>
        initialValues={{ reasons: [], comment: '' }}
        onSubmit={(d) => {
          onSubmit(
            dialogData?.drug.id ?? 0,
            dialogData?.tumor.id ?? 0,
            d.reasons,
            d.comment,
            setSubmitting
          );
          onClose();
        }}
      >
        {({ values: { reasons } }) => {
          const hasOthers = otherReasons.some((i) => reasons.includes(i));
          return (
            <Form>
              <DialogContent>
                <DialogContentText>
                  Select one or more reasons
                </DialogContentText>
                <Field
                  name="reasons"
                  isMulti
                  component={FormikSelect}
                  options={availableReasons.map((r) => ({
                    value: r.id,
                    label: r.name,
                  }))}
                />
                {hasOthers && (
                  <TextField
                    label="Why are you suspending this drug?"
                    name="comment"
                  />
                )}
              </DialogContent>
              <DialogActions>
                <Button onClick={onClose} color="primary">
                  Cancel
                </Button>
                <SubmitButton text="Suspend" isSaving={submitting} />
              </DialogActions>
            </Form>
          );
        }}
      </Formik>
    </Dialog>
  );
}

interface TumorListProps {
  availableReasons: ResourceEntity[];
  patient: PatientEntity;
  refreshPatient: () => void;
}

const TumorList = ({
  availableReasons,
  patient,
  refreshPatient,
}: TumorListProps) => {
  const [dialogData, setDialogData] = useState<DialogData>();
  const connectorService = useService(Connector);

  const stopDrugHandler: ReasonDialogProps['onSubmit'] = (
    drugId,
    tumorId,
    reasons,
    comment,
    setSubmitting
  ) => {
    const endpoint = `detach/${patient.id}/${tumorId}/${drugId}`;
    const params = { reasons, comment };
    connectorService
      .callPost(endpoint, params)
      .then(() => {
        setSubmitting(false);
        refreshPatient();
        return true;
      })
      .catch((e) => {
        console.log(e);
        setSubmitting(false);
      });
  };

  return (
    <>
      <CollapsibleTable
        head={['Tumor', 'Type', 'Location', 'T', 'N', 'M']}
        data={patient.tumors.map((tumor: any) => ({
          id: tumor.id,
          row: [
            tumor.name,
            tumor.type,
            tumor.sede && tumor.sede[0] ? tumor.sede[0].name : '',
            tumor.stadio.T,
            tumor.stadio.N,
            tumor.stadio.M,
          ],
          nestedTable: {
            name: `Drugs for ${tumor.name}`,
            head: ['Drug', 'Start date', 'End date', 'Suspension reasons', ''],
            data: tumor.drugs.map((drug: Drug, i: number) => {
              const reasonNamesArray = (drug.reasons ?? [])
                .map((reason) => reason.name)
                .filter((r) => !r?.toLowerCase().startsWith('other'));
              if (drug.comment) reasonNamesArray.push(drug.comment);
              return {
                id: drug.id,
                data: [
                  drug.name,
                  drug.start_date,
                  drug.end_date ? drug.end_date : 'ongoing...',
                  reasonNamesArray.join(', '),
                  <IconButton
                    key={`suspend-button-${tumor.id}-${drug.id}`}
                    size="small"
                    color="secondary"
                    disabled={!!drug.end_date}
                    title={drug.end_date ? 'Suspended' : 'Suspend'}
                    onClick={async () => {
                      setDialogData({ drug, index: i, tumor });
                    }}
                  >
                    <PauseCircleFilledRoundedIcon />
                  </IconButton>,
                ],
              };
            }),
          },
        }))}
      />
      <ReasonDialog
        onSubmit={stopDrugHandler}
        dialogData={dialogData}
        setDialogData={setDialogData}
        availableReasons={availableReasons}
      />
    </>
  );
};

export default TumorList;
