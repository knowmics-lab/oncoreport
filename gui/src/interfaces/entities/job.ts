import { MapType, Nullable } from '../common';
import IdentifiableEntity from '../common/identifiableEntity';
import TimedEntity from '../common/timedEntity';
import { Patient } from './patient';
import { JobStatus, JobTypes, OutputTypes } from '../enums';

export interface JobPath {
  path: string;
  url: string;
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
