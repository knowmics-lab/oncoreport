import React, { useMemo, useState } from 'react';
import {
  JobEntity,
  JobRepository,
  Settings,
  Utils,
} from '../../../api';
import { Alignment, RowActionType } from '../UI/Table/types';
import { runAsync } from '../utils';
import { useService } from '../../../reactInjector';
import {
  JobObject,
  JobStatus,
  OutputTypes,
  TypeOfNotification,
} from '../../../interfaces';
import SaveResultsMenu from '../UI/saveResultsMenu';
import LogsDialog from '../UI/LogsDialog';
import RepositoryTable from '../UI/RepositoryTable';

export default function Patients() {
  const jobsRepository = useService(JobRepository);
  const [currentPage, setCurrentPage] = useState(1);
  const [submittingJobs, setSubmittingJobs] = useState<number[]>([]);
  const [selectedJob, setSelectedJob] = useState<JobEntity | undefined>();
  const [logsOpen, setLogsOpen] = useState(false);
  const settings = useService(Settings);

  const actions: RowActionType<JobObject, JobEntity>[] = useMemo(() => {
    const js = (r: JobEntity) => !!r.id && submittingJobs.includes(r.id);
    const isReady = (r: JobEntity) => r.status === JobStatus.ready;
    const isQueued = (r: JobEntity) => r.status === JobStatus.queued;
    const isCompleted = (r: JobEntity) => r.status === JobStatus.completed;
    const isReport = (r: JobEntity) =>
      r.output?.type === OutputTypes.tumorNormal ||
      r.output?.type === OutputTypes.tumorOnly;
    return [
      {
        shown: (r) => isReady(r) && !js(r),
        icon: 'fas fa-play',
        color: 'primary',
        tooltip: 'Submit',
        onClick(e, job) {
          e.preventDefault();
          if (job.id) {
            const { id } = job;
            setSubmittingJobs((o) => [...o, id]);
            runAsync(async () => {
              await job.submit();
              setSubmittingJobs((o) => [...o.filter((k) => k !== id)]);
            });
          }
        },
      },
      {
        disabled: true,
        shown: (r) => isReady(r) && js(r),
        icon: 'fas fa-circle-notch fa-spin',
        color: 'primary',
        tooltip: 'Submitting...',
        onClick(e) {
          e.preventDefault();
        },
      },
      {
        shown: (r) => !isReady(r) && !isQueued(r),
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
        shown: (r) => settings.isLocal() && isCompleted(r) && isReport(r),
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
        shown: (r) => isCompleted(r) && isReport(r),
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
        onClick(_e, job) {
          runAsync(async (manager) => {
            await job.delete();
            manager.pushSimple('Job deleted!', TypeOfNotification.success);
            await jobsRepository.refreshPage(currentPage);
          });
        },
      },
    ];
  }, [currentPage, jobsRepository, settings, submittingJobs]);

  return (
    <>
      <RepositoryTable<JobObject, JobEntity, JobRepository>
        repositoryToken={JobRepository}
        title="Jobs"
        onPageChange={(page) => setCurrentPage(page)}
        toolbar={[
          {
            align: Alignment.right,
            shown: true,
            icon: 'fas fa-redo',
            disabled: (s) => s.isLoading,
            tooltip: 'Refresh',
            onClick: (_e, s) => {
              if (s.currentPage) {
                const page = s.currentPage;
                runAsync(async () => {
                  await jobsRepository.refreshPage(page);
                });
              }
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
          runAsync(async () => {
            setLogsOpen(false);
            setSelectedJob(undefined);
            await jobsRepository.refreshPage(currentPage);
          });
        }}
      />
    </>
  );
}
