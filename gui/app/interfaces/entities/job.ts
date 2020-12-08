import { MapType, Nullable } from '../common';
import IdentifiableEntity from '../common/identifiableEntity';
import TimedEntity from '../common/timedEntity';
import { Patient } from './patient';

export interface JobPath {
  path: string;
  url: string;
}

export enum OutputTypes {
  confirmation = 'confirmation',
  tumorOnly = 'tumor-only',
  tumorNormal = 'tumor-vs-normal',
}

export enum JobStatus {
  ready = 'ready',
  queued = 'queued',
  processing = 'processing',
  completed = 'completed',
  failed = 'failed',
}

export enum JobTypes {
  empty = '',
  tumorOnly = 'tumor_only_analysis_job_type',
  tumorNormal = 'tumor_vs_normal_analysis_job_type',
}

export type JobConfig = MapType;

export interface JobOutput {
  type: OutputTypes;
}

export interface Job extends IdentifiableEntity, TimedEntity {
  sample_code?: string;
  name: string;
  type: JobTypes;
  readable_type: string;
  status: JobStatus;
  parameters?: JobConfig;
  log?: string;
  output?: JobOutput;
  owner: unknown;
  patient: Nullable<Patient>;
}
