import Connector from './connector';
import { Nullable, ResponseType } from '../interfaces/common';
import { Job } from '../interfaces/jobs';
import {
  JobConfig,
  TumorNormalAnalysisConfig,
  TumorOnlyAnalysisConfig,
} from '../interfaces/analysis';
import { Patient } from '../interfaces/patients';
import { TumorNormalJob, TumorOnlyJob } from '../interfaces/extended_jobs';

interface ApiResponse {
  data: Omit<Job, 'links'>;
  links: Job['links'];
}

async function realJobSubmit<T extends Job>(
  sample_code: string,
  name: string,
  type: string,
  parameters: JobConfig,
  patient_id?: Nullable<number>
): Promise<ResponseType<T>> {
  const result = await Connector.callPost<ApiResponse>('jobs', {
    sample_code,
    name,
    type,
    parameters,
    patient_id,
  });
  if (!result.data) {
    return {
      validationErrors: result.validationErrors,
    };
  }
  const { data, links } = result.data;
  const job = {
    ...data,
    links,
  };
  return {
    data: job as T,
  };
}

export default {
  async createTumorNormal(
    code: string,
    name: string,
    parameters: TumorNormalAnalysisConfig,
    patient: Patient | number
  ): Promise<ResponseType<TumorNormalJob>> {
    const pId = typeof patient === 'object' ? patient.id : patient;
    return realJobSubmit(
      code,
      name,
      'tumor_vs_normal_analysis_job_type',
      parameters,
      pId
    );
  },
  async createTumorOnly(
    code: string,
    name: string,
    parameters: TumorOnlyAnalysisConfig,
    patient: Patient | number
  ): Promise<ResponseType<TumorOnlyJob>> {
    const pId = typeof patient === 'object' ? patient.id : patient;
    return realJobSubmit(
      code,
      name,
      'tumor_only_analysis_job_type',
      parameters,
      pId
    );
  },
};
