// noinspection SuspiciousTypeOfGuard

import React, { useMemo, useRef, useState } from 'react';
import { JobEntity, JobRepository, Settings, Utils } from '../../../api';
import { Alignment, RowActionType } from '../components/ui/Table/types';
import { runAsync } from '../components/utils';
import { useService } from '../../../reactInjector';
import {
  JobStatus,
  OutputTypes,
  TypeOfNotification,
} from '../../../interfaces';
import SaveResultsMenu from '../components/ui/saveResultsMenu';
import LogsDialog from '../components/ui/LogsDialog';
import RepositoryTable, {
  RepositoryTableRef,
} from '../components/ui/RepositoryTable';
import { ResultSet } from '../../../apiConnector';
import useArray from '../hooks/useArray';

export default function Jobs() {
  const {
    array: submittingJobs,
    push: pushJob,
    remove: removeJob,
  } = useArray<number>();
  const [selectedJob, setSelectedJob] = useState<JobEntity | undefined>();
  const [logsOpen, setLogsOpen] = useState(false);
  const settings = useService(Settings);
  const tableRef = useRef<RepositoryTableRef>();

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
        onClick(e) {
          e.preventDefault();
        },
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
        shown: (r) => r.status !== JobStatus.processing,
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
        repositoryToken={JobRepository}
        tableRef={tableRef}
        title="Jobs"
        toolbar={[
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
        autoRefresh
        autoRefreshWhen={(data) =>
          data.some((j) =>
            [JobStatus.queued, JobStatus.processing].includes(j.status),
          )
        }
      />
      <LogsDialog
        job={selectedJob}
        open={logsOpen}
        onClose={() => {
          runAsync(async () => {
            setLogsOpen(false);
            runAsync(async () => {
              if (selectedJob) {
                await selectedJob.refresh();
                setSelectedJob(undefined);
              }
            });
          });
        }}
      />
    </>
  );
}
