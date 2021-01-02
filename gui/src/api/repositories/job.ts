import { singleton } from 'tsyringe';
import { get, has, set, unset } from 'lodash';
import uniqid from 'uniqid';
import Repository from './repository';
import type { JobObject, Collection, SimpleMapArray } from '../../interfaces';
import Patient from '../entities/patient';
import { JobEntity } from '../entities';
import { JobAdapter } from '../adapters';
import EntityError from '../../errors/EntityError';
import { SimpleMapType } from '../../interfaces';

type RefreshListener = (patient: Patient, page?: number) => void;

@singleton()
export default class Job extends Repository<JobObject, JobEntity> {
  private pagesCacheByPatient: SimpleMapArray<
    SimpleMapArray<Collection<JobEntity>>
  > = {};

  protected refreshListenersByPatient: SimpleMapArray<
    SimpleMapType<RefreshListener>
  > = {};

  public constructor(adapter: JobAdapter) {
    super(adapter, JobEntity);
  }

  private setCachedPage(id: number, page: number, d: Collection<JobEntity>) {
    if (!has(this.pagesCacheByPatient, id)) {
      set(this.pagesCacheByPatient, id, {});
    }
    set(get(this.pagesCacheByPatient, id), page, d);
  }

  public async refreshPageByPatient(
    patient: Patient,
    page: number
  ): Promise<Collection<JobEntity>> {
    if (!patient.id) throw new EntityError('Invalid patient object');
    if (has(this.pagesCacheByPatient, `${patient.id}.${page}`)) {
      unset(this.pagesCacheByPatient, `${patient.id}.${page}`);
    }
    const result = await this.fetchPageByPatient(patient, page);
    this.notifyRefreshByPatient(patient, page);
    return result;
  }

  public async refreshAllPagesByPatient(
    patient: Patient
  ): Promise<Collection<JobEntity>> {
    if (!patient.id) throw new EntityError('Invalid patient object');
    if (has(this.pagesCacheByPatient, `${patient.id}`)) {
      unset(this.pagesCacheByPatient, `${patient.id}`);
    }
    const result = await this.fetchPageByPatient(patient);
    this.notifyRefreshByPatient(patient);
    return result;
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
      this.setCachedPage(id, page, {
        data: tmp.data.map((v) => this.entityFactory(v)),
        meta: tmp.meta,
      });
    }
    return get(this.pagesCacheByPatient, `${id}.${page}`);
  }

  public subscribeRefreshByPatient(
    patient: Patient,
    listener: RefreshListener
  ): string {
    if (!patient.id) throw new EntityError('Invalid patient object');
    const id = uniqid();
    if (!has(this.refreshListenersByPatient, patient.id)) {
      set(this.refreshListenersByPatient, patient.id, {});
    }
    set(get(this.refreshListenersByPatient, patient.id), id, listener);
    return id;
  }

  public unsubscribeRefreshByPatient(patient: Patient, id: string) {
    unset(this.refreshListenersByPatient, `${patient.id}.${id}`);
  }

  private notifyRefreshByPatient(patient: Patient, page?: number) {
    Object.values(
      get(this.refreshListenersByPatient, `${patient.id}`, {})
    ).forEach((l) => (l as RefreshListener)(patient, page));
  }
}
