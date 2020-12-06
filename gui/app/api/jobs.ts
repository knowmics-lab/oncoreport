/* eslint-disable @typescript-eslint/naming-convention */
import path from 'path';
import fs from 'fs-extra';
import { api as electron } from 'electron-util';
import Settings from './settings';
import { Job, JobCollectionItem, JobsCollection } from '../interfaces/jobs';
import { MetaResponseType, SortingSpec } from '../interfaces/common';
import Connector from './connector';
import Downloader from './downloader';
import ApiError from '../errors/ApiError';
import { isTumorNormalJob, isTumorOnlyJob } from '../interfaces/extended_jobs';
import { Utils } from './index';
import { Patient } from '../interfaces/patients';

interface ApiResponseSingle {
  data: Omit<Job, 'links'>;
  links: Job['links'];
}

interface ApiResponseCollection {
  data: JobCollectionItem[];
  meta: MetaResponseType;
}

export default {
  getUploadUrl(job: number | Job): string {
    let jobId;
    if (typeof job === 'object') {
      jobId = job.id;
    } else {
      jobId = job;
    }
    return Connector.getEndpointUrl(`jobs/${jobId}/upload`);
  },
  getLocalDirectory(job: number | Job): string {
    const jobId = typeof job === 'object' ? job.id : job;
    return Settings.getLocalPath(`/public/jobs/${jobId}`);
  },
  async download(
    jobId: number,
    outputVariable: string,
    onStart?: (s: string) => void,
    onCompleted?: (s: string) => void
  ): Promise<void> {
    const job = await this.fetchJobById(jobId);
    if (job.output && Utils.hasPathProperty(job.output, outputVariable)) {
      const { path: outputPath } = job.output[outputVariable];
      const outputUrl = Settings.getPublicUrl(outputPath);
      const outputFilename = path.basename(outputPath);
      Downloader.downloadUrl(
        outputUrl,
        outputFilename,
        () => onStart && onStart(outputVariable),
        () => onCompleted && onCompleted(outputVariable)
      );
    } else {
      throw new Error('Unable to find output path');
    }
  },
  async openLocalFolder(jobId: number): Promise<void> {
    if (!Settings.isLocal())
      throw new Error('Unable to open folder when in remote mode');
    const job = await this.fetchJobById(jobId);
    if (isTumorOnlyJob(job) || isTumorNormalJob(job)) {
      const outputPath = job.output?.reportOutputFile?.path;
      if (outputPath) {
        const jobFolder = path.dirname(
          Settings.getLocalPath(`/public/${outputPath}`)
        );
        if (!(await fs.pathExists(jobFolder)))
          throw new Error('Unable to find output path');
        if (!electron.shell.openItem(jobFolder)) {
          throw new Error('Unable to open output folder');
        }
        return;
      }
    }
    throw new Error('Unable to find output path');
  },
  async openReport(jobId: number): Promise<Window> {
    const job = await this.fetchJobById(jobId);
    if (isTumorOnlyJob(job) || isTumorNormalJob(job)) {
      const reportPath = job.output?.reportOutputFile?.path;
      if (!reportPath) throw new Error('Unable to get report url');
      const reportUrl = Settings.getPublicUrl(reportPath);
      const win = window.open(reportUrl, '_blank', 'nodeIntegration=no');
      if (!win) throw new Error('Unable to open browser window');
      win.focus();
      return win;
    }
    throw new Error('This job does not contain any report file');
  },
  async processDeletedList(deleted: number[]): Promise<number[]> {
    if (deleted.length === 0) return deleted;
    const deletedPromises = deleted.map(
      (id) =>
        new Promise((resolve) => {
          this.fetchJobById(id)
            .then(() => resolve(true))
            .catch(() => resolve(false));
        })
    );
    const res = await Promise.all(deletedPromises);
    return deleted.filter((_v, idx) => res[idx]);
  },
  async deleteJob(jobId: number): Promise<void> {
    await Connector.callDelete(`jobs/${jobId}`);
  },
  async submitJob(jobId: number): Promise<Job> {
    const result = await Connector.callGet<ApiResponseSingle>(
      `jobs/${jobId}/submit`
    );
    if (!result.data) throw new ApiError('Unable to fetch job');
    const { data, links } = result.data;
    return {
      ...data,
      links,
    };
  },
  async fetchJobById(jobId: number): Promise<Job> {
    const result = await Connector.callGet<ApiResponseSingle>(`jobs/${jobId}`);
    if (!result.data) throw new ApiError('Unable to fetch job');
    const { data, links } = result.data;
    return {
      ...data,
      links,
    };
  },
  async fetchJobs(
    per_page = 15,
    sorting: SortingSpec = { created_at: 'desc' },
    page = 1
  ): Promise<JobsCollection> {
    const order = Object.keys(sorting);
    const order_direction = Object.values(sorting);
    const result = await Connector.callGet<ApiResponseCollection>(`jobs`, {
      page,
      per_page,
      order,
      order_direction,
    });
    if (!result.data) throw new ApiError('Unable to fetch jobs');
    const { data, meta } = result.data;
    return {
      data: data.map(
        (x): Job => ({
          ...x,
          links: {
            self: x.self_link,
            owner: x.owner_link,
            patient: x.patient_link,
            upload: x.upload_link,
            submit: x.submit_link,
          },
        })
      ),
      meta: {
        ...meta,
        sorting,
      },
    };
  },
  async fetchJobsByPatient(
    patient: number | Patient,
    per_page = 15,
    sorting: SortingSpec = { created_at: 'desc' },
    page = 1
  ): Promise<JobsCollection> {
    const id = typeof patient === 'object' ? patient.id : patient;
    const order = Object.keys(sorting);
    const order_direction = Object.values(sorting);
    const result = await Connector.callGet<ApiResponseCollection>(
      `jobs/by_patient/${id}`,
      {
        page,
        per_page,
        order,
        order_direction,
      }
    );
    if (!result.data) throw new ApiError('Unable to fetch jobs');
    const { data, meta } = result.data;
    return {
      data: data.map(
        (x): Job => ({
          ...x,
          links: {
            self: x.self_link,
            owner: x.owner_link,
            patient: x.patient_link,
            upload: x.upload_link,
            submit: x.submit_link,
          },
        })
      ),
      meta: {
        ...meta,
        sorting,
      },
    };
  },
  // async fetchAllByType(type: string): Promise<Job[]> {
  //   const result = await Connector.callGet(`jobs`, {
  //     per_page: 0,
  //     deep_type: type,
  //     completed: true,
  //   });
  //   const { data } = result.data;
  //   return data.map((x) => ({
  //     ...x,
  //     links: {
  //       self: x.self,
  //       upload: x.upload,
  //       submit: x.submit,
  //     },
  //   }));
  // },
};
