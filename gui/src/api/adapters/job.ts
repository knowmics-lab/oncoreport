/* eslint-disable @typescript-eslint/naming-convention */
import { singleton } from 'tsyringe';
import Connector from './connector';
import {
  Adapter,
  ApiResponseCollection,
  ApiResponseSingle,
  Collection,
  IdentifiableEntity,
  JobObject,
  PatientObject,
  SortingDirection,
  SortingSpec,
} from '../../interfaces';
import ApiError from '../../errors/ApiError';
import ApiValidationError from '../../errors/ApiValidationError';

@singleton()
export default class Job implements Adapter<JobObject> {
  public constructor(public readonly connector: Connector) {}

  public async create(job: JobObject): Promise<JobObject> {
    const result = await this.connector.callPost<ApiResponseSingle<JobObject>>(
      'jobs',
      {
        sample_code: job.sample_code,
        name: job.name,
        type: job.type,
        parameters: job.parameters,
        patient_id: job.patient?.id,
      }
    );
    if (!result.data) {
      throw new ApiValidationError(
        'Error occurred during validation of input data',
        result.validationErrors
      );
    }
    return result.data.data;
  }

  public async update(job: JobObject): Promise<JobObject> {
    if (!job.id) {
      throw new ApiError(
        'This object cannot be updated since no id is present'
      );
    }
    const result = await this.connector.callPatch<ApiResponseSingle<JobObject>>(
      `jobs/${job.id}`,
      {
        sample_code: job.sample_code,
        name: job.name,
        parameters: job.parameters,
        patient_id: job.patient?.id,
      }
    );
    if (!result.data) {
      throw new ApiValidationError(
        'Error occurred during validation of input data',
        result.validationErrors
      );
    }
    return result.data.data;
  }

  public async submit(job: JobObject): Promise<JobObject> {
    if (!job.id) {
      throw new ApiError(
        'This object cannot be submitted since no id is present'
      );
    }
    const result = await this.connector.callGet<ApiResponseSingle<JobObject>>(
      `jobs/${job.id}/submit`
    );
    if (!result.data) throw new ApiError('Unable to submit the job');
    return result.data.data;
  }

  public async delete(job: JobObject): Promise<void> {
    if (!job.id) {
      throw new ApiError(
        'This object cannot be deleted since no id is present'
      );
    }
    await this.connector.callDelete(`jobs/${job.id}`);
  }

  public async fetchOne(id: number | IdentifiableEntity): Promise<JobObject> {
    const realId = typeof id === 'number' ? id : id.id;
    if (!realId) {
      throw new ApiError('No valid id specified');
    }
    const result = await this.connector.callGet<ApiResponseSingle<JobObject>>(
      `jobs/${realId}`
    );
    if (!result.data) throw new ApiError('Unable to fetch the job');
    return result.data.data;
  }

  public async fetchPage(
    per_page = 15,
    sorting: SortingSpec = { created_at: SortingDirection.desc },
    page = 1
  ): Promise<Collection<JobObject>> {
    const order = Object.keys(sorting);
    const order_direction = Object.values(sorting);
    const result = await this.connector.callGet<
      ApiResponseCollection<JobObject>
    >(`jobs`, {
      page,
      per_page,
      order,
      order_direction,
    });
    if (!result.data) throw new ApiError('Unable to fetch jobs');
    const { data, meta } = result.data;
    return {
      data,
      meta: {
        ...meta,
        sorting,
      },
    };
  }

  public async fetchPageByPatient(
    patient: number | PatientObject,
    per_page = 15,
    sorting: SortingSpec = { created_at: SortingDirection.desc },
    page = 1
  ): Promise<Collection<JobObject>> {
    const id = typeof patient === 'object' ? patient.id : patient;
    const order = Object.keys(sorting);
    const order_direction = Object.values(sorting);
    const result = await this.connector.callGet<
      ApiResponseCollection<JobObject>
    >(`jobs/by_patient/${id}`, {
      page,
      per_page,
      order,
      order_direction,
    });
    if (!result.data) throw new ApiError('Unable to fetch jobs');
    const { data, meta } = result.data;
    return {
      data,
      meta: {
        ...meta,
        sorting,
      },
    };
  }

  public async processDeletedList(deleted: number[]): Promise<number[]> {
    if (deleted.length === 0) return deleted;
    const deletedPromises = deleted.map(
      (id) =>
        new Promise<boolean>((resolve) => {
          this.connector
            .callGet(`jobs/${id}`)
            .then(() => resolve(true))
            .catch(() => resolve(false));
        })
    );
    const res = await Promise.all(deletedPromises);
    return deleted.filter((_v, idx) => res[idx]);
  }
}
