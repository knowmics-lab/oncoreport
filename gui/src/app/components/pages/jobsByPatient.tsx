import React, { useEffect, useMemo, useState } from 'react';
import { useHistory, useParams } from 'react-router-dom';
import {
  Backdrop,
  CircularProgress,
  createStyles,
  makeStyles,
} from '@material-ui/core';
import { generatePath } from 'react-router';
import {
  JobEntity,
  JobRepository,
  PatientEntity,
  PatientRepository,
  Settings,
  Utils,
} from '../../../api';
import { Alignment, RowActionType } from '../UI/Table/types';
import { runAsync } from '../utils';
import { useService } from '../../../reactInjector';
import JobsTableByPatient from '../UI/JobsTableByPatient';
import Routes from '../../../constants/routes.json';
import {
  JobObject,
  JobStatus,
  OutputTypes,
  TypeOfNotification,
} from '../../../interfaces';
import SaveResultsMenu from '../UI/saveResultsMenu';

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
  const jobsRepository = useService(JobRepository);
  const patientsRepository = useService(PatientRepository);
  const patientId: number = +useParams<{ id: string }>().id;
  const [patient, setPatient] = useState<PatientEntity | undefined>(undefined);
  const [currentPage, setCurrentPage] = useState(1);
  const [submittingJobs, setSubmittingJobs] = useState<number[]>([]);
  const settings = useService(Settings);
  const history = useHistory();

  useEffect(() => {
    if (!patient || (patient && patient.id !== patientId)) {
      runAsync(async () => {
        setPatient(await patientsRepository.fetch(patientId));
      });
    }
  }, [patient, patientId, patientsRepository]);

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
          if (patient) {
            e.preventDefault();
            runAsync(async () => {
              await job.refresh();
              await jobsRepository.refreshPageByPatient(patient, currentPage);
              await jobsRepository.refreshAllPages();
            });
          }
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
          if (patient) {
            runAsync(async (manager) => {
              await job.delete();
              manager.pushSimple('Job deleted!', TypeOfNotification.success);
              await jobsRepository.refreshPageByPatient(patient, currentPage);
              await jobsRepository.refreshAllPages();
            });
          }
        },
      },
    ];
  }, [currentPage, jobsRepository, patient, settings, submittingJobs]);

  return (
    <>
      {patient ? (
        <>
          <JobsTableByPatient
            patient={patient}
            title={`Analysis of ${patient.first_name} ${patient.last_name}`}
            onPageChange={(page) => setCurrentPage(page)}
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
                icon: 'fas fa-redo',
                disabled: (s) => s.isLoading,
                tooltip: 'Refresh',
                onClick: (_e, s) => {
                  if (s.currentPage) {
                    const page = s.currentPage;
                    runAsync(async () => {
                      await jobsRepository.refreshPageByPatient(patient, page);
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
