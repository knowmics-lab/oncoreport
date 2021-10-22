/* eslint-disable @typescript-eslint/no-explicit-any */
import { sprintf } from 'sprintf-js';
import Client from './httpClient/client';
import { MapType, PartialObject, SimpleMapType } from './interfaces/common';
import { QueryRequest } from './interfaces/queryRequest';
import { Adapter as IAdapter } from './interfaces/adapter';
import QueryResponse from './interfaces/queryResponse';
import ApiError from '../errors/ApiError';
import { ApiResponseSingle } from './interfaces/apiResponses';
import ApiValidationError from '../errors/ApiValidationError';

export default abstract class Adapter<T> implements IAdapter<T> {
  protected constructor(public readonly client: Client) {}

  protected isReadOnly = false;

  abstract get endpoint(): string;

  protected getEndpointForResource(id: number): string {
    return `${this.endpoint}/${id}`;
  }

  // eslint-disable-next-line class-methods-use-this
  protected prepareEntityForCreate(entity: PartialObject<T>): MapType {
    return entity as unknown as MapType;
  }

  // eslint-disable-next-line class-methods-use-this
  protected prepareEntityForUpdate(entity: PartialObject<T>): MapType {
    return entity as unknown as MapType;
  }

  async create(entity: PartialObject<T>): Promise<PartialObject<T>> {
    if (this.isReadOnly) {
      throw new ApiError('This operation is not supported');
    }
    const endpoint = sprintf(this.endpoint, entity);
    const result = await this.client.post<ApiResponseSingle<PartialObject<T>>>(
      endpoint,
      this.prepareEntityForCreate(entity)
    );
    if (!result.data) {
      throw new ApiValidationError(
        'Error occurred during validation of input data',
        result.validationErrors
      );
    }
    return result.data.data;
  }

  async update(
    id: number | (PartialObject<T> & { id: number }) | (T & { id: number }),
    entity: PartialObject<T>
  ): Promise<PartialObject<T>> {
    if (this.isReadOnly) {
      throw new ApiError('This operation is not supported');
    }
    const entityId = typeof id === 'number' ? id : id.id;
    const endpoint = sprintf(this.getEndpointForResource(entityId), entity);
    const result = await this.client.post<ApiResponseSingle<PartialObject<T>>>(
      endpoint,
      this.prepareEntityForUpdate(entity)
    );
    if (!result.data) {
      throw new ApiValidationError(
        'Error occurred during validation of input data',
        result.validationErrors
      );
    }
    return result.data.data;
  }

  async delete(
    id: number | (PartialObject<T> & { id: number }) | (T & { id: number }),
    parameters?: SimpleMapType<any>
  ): Promise<void> {
    if (this.isReadOnly) {
      throw new ApiError('This operation is not supported');
    }
    const entityId = typeof id === 'number' ? id : id.id;
    const endpoint = sprintf(this.getEndpointForResource(entityId), parameters);
    await this.client.delete(endpoint);
  }

  find(
    id: number | (PartialObject<T> & { id: number }) | (T & { id: number }),
    parameters?: SimpleMapType<any>
  ): Promise<PartialObject<T>> {
    return Promise.resolve(undefined);
  }

  query(
    queryRequest?: QueryRequest,
    parameters?: SimpleMapType<any>
  ): Promise<QueryResponse<T>> {
    return Promise.resolve(undefined);
  }
}
