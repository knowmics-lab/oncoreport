import { singleton } from 'tsyringe';
import { get, has, set, unset } from 'lodash';
import Repository from './repository';
import type { JobObject, Collection, SimpleMapArray } from '../../interfaces';
import Patient from '../entities/patient';
import { JobEntity } from '../entities';
import { JobAdapter } from '../adapters';
import EntityError from '../../errors/EntityError';

@singleton()
export default class Job extends Repository<JobObject, JobEntity> {
  private pagesCacheByPatient: SimpleMapArray<
    SimpleMapArray<Collection<Job>>
  > = {};

  public constructor(adapter: JobAdapter) {
    super(adapter, JobEntity);
  }

  public refreshPageByPatient(
    patient: Patient,
    page: number
  ): Promise<Collection<JobEntity>> {
    if (!patient.id) throw new EntityError('Invalid patient object');
    if (has(this.pagesCacheByPatient, `${patient.id}.${page}`)) {
      unset(this.pagesCacheByPatient, `${patient.id}.${page}`);
    }
    return this.fetchPageByPatient(patient, page);
  }

  public refreshAllPagesByPatient(
    patient: Patient
  ): Promise<Collection<JobEntity>> {
    if (!patient.id) throw new EntityError('Invalid patient object');
    if (has(this.pagesCacheByPatient, `${patient.id}`)) {
      unset(this.pagesCacheByPatient, `${patient.id}`);
    }
    return this.fetchPageByPatient(patient);
  }

  public async fetchPageByPatient(
    patient: Patient,
    page = 1
  ): Promise<Collection<JobEntity>> {
    const { id } = patient;
    if (!id) throw new EntityError('Invalid patient object');
    if (!has(this.pagesCacheByPatient, `${id}.${page}`)) {
      const tmp = await (this.adapter as JobAdapter).fetchPageByPatient(
        patient,
        this.itemsPerPage,
        this.sorting,
        page
      );
      set(this.pagesCacheByPatient, `${patient.id}.${page}`, {
        data: tmp.data.map((v) => this.entityFactory(v)),
        meta: tmp.meta,
      });
    }
    return get(this.pagesCacheByPatient, `${id}.${page}`);
  }
}
