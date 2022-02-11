// noinspection SuspiciousTypeOfGuard

import React, { useMemo, useState } from 'react';
import { useHistory } from 'react-router-dom';
import { generatePath } from 'react-router';
import {
  JobEntity,
  JobRepository,
  PatientEntity,
  Settings,
  Utils,
} from '../../../../api';
import RepositoryTable from '../../ui/RepositoryTable';
import { Alignment, RowActionType } from '../../ui/Table/types';
import {
  JobStatus,
  OutputTypes,
  TypeOfNotification,
} from '../../../../interfaces';
import { runAsync } from '../../utils';
import SaveResultsMenu from '../../ui/saveResultsMenu';
import useArray from '../../../hooks/useArray';
import { useService } from '../../../../reactInjector';
import Routes from '../../../../constants/routes.json';
import { ResultSet } from '../../../../apiConnector';
import LogsDialog from '../../ui/LogsDialog';

export type TableProps = {
  title?: string;
  patient: PatientEntity | number;
  backRoute?: string;
  doNotWrap?: boolean;
};

export default function JobsTableByPatient({
  title,
  patient,
  backRoute,
  doNotWrap,
}: TableProps) {
  const patientId = useMemo(
    () => (typeof patient === 'number' ? patient : patient.id),
    [patient]
  );
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
        onClick(_e, job, setLoading) {
          runAsync(async (manager) => {
            if (setLoading) setLoading(true);
            await job.delete();
            manager.pushSimple('Job deleted!', TypeOfNotification.success);
            if (setLoading) setLoading(false);
          });
        },
      },
    ];
  }, [pushJob, removeJob, settings, submittingJobs]);

  return (
    <>
      <RepositoryTable
        title={title}
        doNotWrap={doNotWrap}
        toolbar={[
          {
            align: Alignment.left,
            color: 'default',
            disabled: false,
            icon: 'fas fa-arrow-left',
            shown: !!backRoute,
            tooltip: 'Go Back',
            onClick() {
              history.push(backRoute ?? '');
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
                  id: patientId,
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
        repositoryToken={JobRepository}
        parameters={{
          patient: patientId,
        }}
        autoRefresh
        autoRefreshWhen={(data) =>
          data.some((j) =>
            [JobStatus.queued, JobStatus.processing].includes(j.status)
          )
        }
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
  );
}
