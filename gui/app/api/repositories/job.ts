import { singleton } from 'tsyringe';
import Repository from './repository';
import { Job as JobObject } from '../../interfaces/entities/job';
import { SortingSpec } from '../../interfaces/common';
import { Collection } from '../../interfaces/collection';
import Patient from '../entities/patient';
import { JobEntity } from '../entities';
import { JobAdapter } from '../adapters';

@singleton()
export default class Job extends Repository<JobObject, JobEntity> {
  public constructor(adapter: JobAdapter) {
    super(adapter, JobEntity);
  }

  public async fetchPageByPatient(
    patient: Patient,
    per_page = 15,
    sorting: SortingSpec = { created_at: 'desc' },
    page = 1
  ): Promise<Collection<JobEntity>> {
    const tmpCollection = await (this.adapter as JobAdapter).fetchPageByPatient(
      patient,
      per_page,
      sorting,
      page
    );
    return {
      data: tmpCollection.data.map((v) =>
        this.makeEntity().fillFromCollection(v)
      ),
      meta: tmpCollection.meta,
    };
  }
}
