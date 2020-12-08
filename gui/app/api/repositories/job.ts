import { injectable } from 'tsyringe';
import Repository from './repository';
import { Job as JobObject } from '../../interfaces/entities/job';
import JobEntity from '../entities/job';
import JobAdapter from '../adapters/job';

@injectable()
export default class Job extends Repository<JobObject, JobEntity> {
  public constructor(adapter: JobAdapter) {
    super(adapter, JobEntity);
  }
}
