/* eslint-disable @typescript-eslint/naming-convention,class-methods-use-this */
import { singleton } from 'tsyringe';
import Connector from './connector';
import ApiError from '../../errors/ApiError';
import {
  DiseaseObject,
  SimpleMapArray,
  Adapter,
  Collection,
  ApiResponseSingle,
  IdentifiableEntity,
} from '../../interfaces';

@singleton()
export default class Disease implements Adapter<DiseaseObject> {
  public constructor(public readonly connector: Connector) {}

  public async create(): Promise<never> {
    throw new ApiError('This operation is not supported');
  }

  public async update(): Promise<never> {
    throw new ApiError('This operation is not supported');
  }

  public async delete(): Promise<never> {
    throw new ApiError('This operation is not supported');
  }

  public async fetchOne(
    id: number | IdentifiableEntity
  ): Promise<DiseaseObject> {
    const realId = typeof id === 'number' ? id : id.id;
    if (!realId) {
      throw new ApiError('No valid id specified');
    }
    const result = await this.connector.callGet<
      ApiResponseSingle<DiseaseObject>
    >(`diseases/${realId}`);
    if (!result.data) throw new ApiError('Unable to fetch the disease');
    return result.data.data;
  }

  public async fetchPage(): Promise<Collection<DiseaseObject>> {
    const result = await this.connector.callGet<{
      data: SimpleMapArray<DiseaseObject>;
    }>(`diseases`);
    if (!result.data) throw new ApiError('Unable to fetch diseases');
    const { data } = result.data;
    const values = Object.values(data);
    const size = values.length;
    return {
      data: values,
      meta: {
        current_page: 0,
        last_page: 0,
        from: 0,
        to: size - 1,
        per_page: size,
        sorting: {},
        total: size,
      },
    };
  }
}
