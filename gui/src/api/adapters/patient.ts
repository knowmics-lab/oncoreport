/* eslint-disable @typescript-eslint/naming-convention */
import { singleton } from 'tsyringe';
import Connector from './connector';
import {
  PatientObject,
  IdentifiableEntity,
  SortingSpec,
  Collection,
  Adapter,
  ApiResponseCollection,
  ApiResponseSingle,
  SortingDirection,
  DeleteResponse,
} from '../../interfaces';
import ApiError from '../../errors/ApiError';
import ApiValidationError from '../../errors/ApiValidationError';

@singleton()
export default class Patient implements Adapter<PatientObject> {
  public constructor(public readonly connector: Connector) {}

  public async create(patient: PatientObject): Promise<PatientObject> {
    const result = await this.connector.callPost<
      ApiResponseSingle<PatientObject>
    >('patients', {
      code: patient.code,
      first_name: patient.first_name,
      last_name: patient.last_name,
      gender: patient.gender,
      age: patient.age,
      disease_id: patient.disease.id,
      tumors: patient.tumors || null,
      diseases: patient.diseases || null,
      tumor: patient.tumor || null,
      type: patient.type || null,
      drugs: patient.drugs || null,
    });
    if (!result.data) {
      throw new ApiValidationError(
        'Error occurred during validation of input data',
        result.validationErrors
      );
    }
    return result.data.data;
  }

  public async update(patient: PatientObject): Promise<PatientObject> {
    if (!patient.id) {
      throw new ApiError(
        'This object cannot be updated since no id is present'
      );
    }
    const result = await this.connector.callPatch<
      ApiResponseSingle<PatientObject>
    >(`patients/${patient.id}`, {
      code: patient.code,
      first_name: patient.first_name,
      last_name: patient.last_name,
      gender: patient.gender,
      age: patient.age,
      disease_id: patient.disease.id,
      tumors: patient.tumors || null,
      diseases: patient.diseases || null,
      tumor: patient.tumor || null,
      type: patient.type || null,
    });
    if (!result.data) {
      throw new ApiValidationError(
        'Error occurred during validation of input data',
        result.validationErrors
      );
    }
    return result.data.data;
  }

  public async delete(patient: PatientObject): Promise<void> {
    if (!patient.id) {
      throw new ApiError(
        'This object cannot be deleted since no id is present'
      );
    }
    const result = await this.connector.callDelete<DeleteResponse>(
      `patients/${patient.id}`
    );
    if (!result.data) {
      throw new ApiError('Unknown error');
    }
    if (result.data.errors) {
      throw new ApiError(result.data.message);
    }
  }

  public async fetchOne(
    id: number | IdentifiableEntity
  ): Promise<PatientObject> {
    const realId = typeof id === 'number' ? id : id.id;
    if (!realId) {
      throw new ApiError('No valid id specified');
    }
    const result = await this.connector.callGet<
      ApiResponseSingle<PatientObject>
    >(`patients/${realId}`);
    if (!result.data) throw new ApiError('Unable to fetch the patient');
    return result.data.data;
  }

  public async fetchPage(
    per_page = 15,
    sorting: SortingSpec = { created_at: SortingDirection.desc },
    page = 1
  ): Promise<Collection<PatientObject>> {
    const order = Object.keys(sorting);
    const order_direction = Object.values(sorting);
    const result = await this.connector.callGet<
      ApiResponseCollection<PatientObject>
    >(`patients`, {
      page,
      per_page,
      order,
      order_direction,
    });
    if (!result.data) throw new ApiError('Unable to fetch patients');
    const { data, meta } = result.data;
    return {
      data: Object.values(data),
      meta: {
        ...meta,
        sorting,
      },
    };
  }
}
