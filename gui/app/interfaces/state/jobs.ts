import { SimpleMapArray, StatePaginationType } from '../common';
import { Job } from '../entities/job';

export interface JobsCollection<E extends Job> {
  readonly refreshAll: boolean;
  readonly refreshPages: number[];
  readonly state: StatePaginationType;
  readonly pages: SimpleMapArray<E[]>;
}

export interface LoadedJobs<E extends Job> {
  fetching: boolean;
  submitting: number[];
  deleting: number[];
  readonly items: SimpleMapArray<E>;
}

export default interface JobsState<E extends Job> {
  readonly jobsList: JobsCollection<E>;
  readonly jobs: LoadedJobs<E>;
}
