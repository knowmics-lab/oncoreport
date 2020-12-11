import { singleton } from 'tsyringe';
import Repository from './repository';
import type { JobObject, SortingSpec, Collection } from '../../interfaces';
import Patient from '../entities/patient';
import { JobEntity } from '../entities';
import { JobAdapter } from '../adapters';
import { SortingDirection } from '../../interfaces';

@singleton()
export default class Job extends Repository<JobObject, JobEntity> {
  public constructor(adapter: JobAdapter) {
    super(adapter, JobEntity);
  }

  public async fetchPageByPatient(
    patient: Patient,
    per_page = 15,
    sorting: SortingSpec = { created_at: SortingDirection.desc },
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
