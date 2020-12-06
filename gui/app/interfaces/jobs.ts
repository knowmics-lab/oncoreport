import {
  MetaResponseType,
  Nullable,
  SimpleMapType,
  StatePaginationType,
} from './common';
import { PatientCollectionItem } from './patients';
import { JobConfig } from './analysis';

export interface JobPathType {
  path: string;
  url: string;
}

export enum OutputTypes {
  confirmation = 'confirmation',
  tumorOnly = 'tumor-only',
  tumorNormal = 'tumor-vs-normal',
}

export enum JobTypes {
  tumorOnly = 'tumor_only_analysis_job_type',
  tumorNormal = 'tumor_vs_normal_analysis_job_type',
}

export interface JobOutput {
  type: OutputTypes;
}

export interface JobBase {
  id: number;
  sample_code?: string;
  name: string;
  type: JobTypes;
  readable_type: string;
  status: 'ready' | 'queued' | 'processing' | 'completed' | 'failed';
  output?: JobOutput;
  created_at: string;
  created_at_diff: string;
  updated_at: string;
  updated_at_diff: string;
  owner: unknown;
  patient: Nullable<PatientCollectionItem>;
}

export interface Job extends JobBase {
  parameters?: JobConfig;
  log?: string;
  links: {
    self: string;
    owner: string;
    patient: Nullable<string>;
    upload: string;
    submit: string;
  };
}

export interface JobCollectionItem extends JobBase {
  self_link: string;
  owner_link: string;
  patient_link: Nullable<string>;
  upload_link: string;
  submit_link: string;
}

export interface JobsCollection {
  data: Job[];
  meta: MetaResponseType;
}

export interface JobType {
  id: string;
  description: string;
}

export type JobTypesCollection = SimpleMapType<JobType>;

export interface JobsListType {
  readonly refreshAll: boolean;
  readonly refreshPages: number[];
  readonly state: StatePaginationType;
  readonly pages: { readonly [page: number]: Job[] };
}

export interface LoadedJobs {
  fetching: boolean;
  submitting: number[];
  deleting: number[];
  readonly items: { readonly [id: number]: Job };
}

export interface JobsStateType {
  readonly jobsList: JobsListType;
  readonly jobs: LoadedJobs;
}
