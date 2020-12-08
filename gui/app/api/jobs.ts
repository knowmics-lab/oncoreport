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

interface ApiResponseCollection {
  data: JobCollectionItem[];
  meta: MetaResponseType;
}

export default {
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
