import { singleton } from 'tsyringe';
import { JobEntity } from '../entities';
import { JobAdapter } from '../adapters';
import { Repository } from '../../apiConnector';

@singleton()
export default class Job extends Repository<JobEntity> {
  public constructor(adapter: JobAdapter) {
    super(adapter, JobEntity);
  }
}
