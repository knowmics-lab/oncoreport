// noinspection SuspiciousTypeOfGuard

import React, { useMemo, useState } from 'react';
import { useHistory, useParams } from 'react-router-dom';
import {
  Backdrop,
  CircularProgress,
  createStyles,
  makeStyles,
} from '@material-ui/core';
import { generatePath } from 'react-router';
import { JobEntity, Settings, Utils } from '../../../api';
import { Alignment, RowActionType } from '../ui/Table/types';
import { runAsync } from '../utils';
import { useService } from '../../../reactInjector';
import JobsTableByPatient from '../ui/JobsTableByPatient';
import Routes from '../../../constants/routes.json';
import {
  JobStatus,
  OutputTypes,
  TypeOfNotification,
} from '../../../interfaces';
import SaveResultsMenu from '../ui/saveResultsMenu';
import LogsDialog from '../ui/LogsDialog';
import useArray from '../../hooks/useArray';
import { ResultSet } from '../../../apiConnector';

const useStyles = makeStyles((theme) =>
  createStyles({
    backdrop: {
      zIndex: theme.zIndex.drawer + 1,
      color: '#fff',
    },
  })
);

export default function Patients() {
  const classes = useStyles();
  const patient: number = +useParams<{ id: string }>().id;
  const {
    array: submittingJobs,
    push: pushJob,
    remove: removeJob,
  } = useArray<number>();
  const [selectedJob, setSelectedJob] = useState<JobEntity | undefined>();
  const [logsOpen, setLogsOpen] = useState(false);
  const settings = useService(Settings);
  const history = useHistory();

  const actions: RowActionType<JobEntity>[] = useMemo(() => {
    const js = (j: JobEntity) => !j.isNew && submittingJobs.includes(j.id);
    const isReady = (j: JobEntity) => j.status === JobStatus.ready;
    const isQueued = (j: JobEntity) => j.status === JobStatus.queued;
    const isCompleted = (j: JobEntity) => j.status === JobStatus.completed;
    const isReport = (j: JobEntity) =>
      j.output?.type === OutputTypes.tumorNormal ||
      j.output?.type === OutputTypes.tumorOnly;
    return [
      {
        shown: (j) => isReady(j) && !js(j),
        icon: 'fas fa-play',
        color: 'primary',
        tooltip: 'Submit',
        onClick(e, job) {
          e.preventDefault();
          if (!job.isNew) {
            const { id } = job;
            pushJob(id);
            runAsync(async () => {
              await job.submit();
              removeJob(id);
            });
          }
        },
      },
      {
        disabled: true,
        shown: (j) => isReady(j) && js(j),
        icon: 'fas fa-circle-notch fa-spin',
        color: 'primary',
        tooltip: 'Submitting...',
        onClick: (e) => e.preventDefault(),
      },
      {
        shown: (j) => !isReady(j) && !isQueued(j),
        icon: 'fas fa-file-alt',
        tooltip: 'Logs',
        onClick(e, job) {
          e.preventDefault();
          setSelectedJob(job);
          setLogsOpen(true);
        },
      },
      (job, size) => <SaveResultsMenu job={job} size={size} />,
      {
        shown: (j) => settings.isLocal() && isCompleted(j) && isReport(j),
        icon: 'fas fa-folder-open',
        tooltip: 'Open results folder',
        onClick(e, job) {
          e.preventDefault();
          runAsync(async () => {
            return job.openLocalFolder();
          });
        },
      },
      {
        shown: (j) => isCompleted(j) && isReport(j),
        icon: 'fas fa-eye',
        tooltip: 'Show report',
        onClick(e, job) {
          e.preventDefault();
          runAsync(async () => {
            await job.openReport();
          });
        },
      },
      {
        shown: (j) => j.status !== JobStatus.processing,
        color: 'secondary',
        icon: 'fas fa-trash',
        tooltip: 'Delete',
        onClick(_e, job) {
          runAsync(async (manager) => {
            await job.delete();
            manager.pushSimple('Job deleted!', TypeOfNotification.success);
          });
        },
      },
    ];
  }, [pushJob, removeJob, settings, submittingJobs]);

  return (
    <>
      {patient ? (
        <>
          <JobsTableByPatient
            patient={patient}
            title="Patient Analysis"
            toolbar={[
              {
                align: Alignment.left,
                color: 'default',
                disabled: false,
                icon: 'fas fa-arrow-left',
                shown: true,
                tooltip: 'Go Back',
                onClick() {
                  history.push(generatePath(Routes.PATIENTS));
                },
              },
              {
                align: Alignment.right,
                shown: true,
                icon: 'fas fa-plus',
                tooltip: 'New Analysis',
                onClick: () => {
                  history.push(
                    generatePath(Routes.NEW_ANALYSIS, {
                      id: patient,
                    })
                  );
                },
              },
              {
                align: Alignment.right,
                shown: true,
                icon: 'fas fa-redo',
                disabled: (s) => s.isLoading,
                tooltip: 'Refresh',
                onClick: (_e, _s, data) => {
                  runAsync(async () => {
                    if (data && data instanceof ResultSet) {
                      await data.refresh();
                    }
                  });
                },
              },
            ]}
            actions={actions}
            columns={[
              {
                dataField: 'name',
                label: 'Name',
              },
              {
                dataField: 'readable_type',
                sortingField: 'type',
                label: 'Type',
              },
              {
                dataField: 'status',
                label: 'Status',
                format: (v) => Utils.capitalize(v),
              },
              {
                dataField: 'created_at_diff',
                sortingField: 'created_at',
                label: 'Created at',
              },
              'actions',
            ]}
          />
          <LogsDialog
            job={selectedJob}
            open={logsOpen}
            onClose={() => {
              setLogsOpen(false);
              runAsync(async () => {
                if (selectedJob) {
                  await selectedJob.refresh();
                  setSelectedJob(undefined);
                }
              });
            }}
          />
        </>
      ) : (
        <>
          <Backdrop className={classes.backdrop} open={!patient}>
            <CircularProgress color="inherit" />
          </Backdrop>
        </>
      )}
    </>
  );
}
