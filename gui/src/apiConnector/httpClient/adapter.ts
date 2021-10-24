/* eslint-disable class-methods-use-this */
import { sprintf } from 'sprintf-js';
import { get, has } from 'lodash';
import Client from './client';
import { MapType, PartialObject, SimpleMapType } from '../interfaces/common';
import { QueryRequest } from '../interfaces/queryRequest';
import { Adapter as IAdapter } from '../interfaces/adapter';
import QueryResponse from '../interfaces/queryResponse';
import ApiError from '../../errors/ApiError';
import { Single, Collection } from '../interfaces/apiResponses';
import SortingDirection from '../enums/sortingDirection';
import { SortingSpec } from '../../interfaces';

type Serializable<T> = T & { serialize?: () => MapType };
type WithParameters<T> = T & { getParameters?: () => SimpleMapType };

export default abstract class Adapter<T> implements IAdapter<T> {
  protected constructor(public readonly client: Client) {}

  protected defaultPerPage = 15;

  protected defaultPage = 1;

  protected defaultPaginate = true;

  protected defaultSorting: SortingSpec = { created_at: SortingDirection.desc };

  protected isReadOnly = false;

  abstract get endpoint(): string;

  protected getEndpointForResource(id: number): string {
    return `${this.endpoint}/${id}`;
  }

  protected prepareEntityForCreate(
    entity: Serializable<PartialObject<T>>
  ): MapType {
    if (typeof entity.serialize === 'function') {
      return entity.serialize();
    }
    return entity as unknown as MapType;
  }

  protected prepareEntityForUpdate(
    entity: Serializable<PartialObject<T>>
  ): MapType {
    if (typeof entity.serialize === 'function') {
      return entity.serialize();
    }
    return entity as unknown as MapType;
  }

  protected getParameters(
    parameters?: SimpleMapType,
    entity?: WithParameters<PartialObject<T>>
  ): SimpleMapType {
    return {
      ...(parameters ?? {}),
      ...(typeof entity?.getParameters === 'function'
        ? entity.getParameters()
        : entity ?? {}),
    };
  }

  async create(entity: PartialObject<T>): Promise<PartialObject<T>> {
    if (this.isReadOnly) {
      throw new ApiError('This operation is not supported');
    }
    const endpoint = sprintf(
      this.endpoint,
      this.getParameters(undefined, entity)
    );
    const { data } = await this.client.post<Single<PartialObject<T>>>(
      endpoint,
      this.prepareEntityForCreate(entity)
    );
    return data;
  }

  async update(
    entity: PartialObject<T> & { id: number }
  ): Promise<PartialObject<T>> {
    if (this.isReadOnly) {
      throw new ApiError('This operation is not supported');
    }
    const { id } = entity;
    const endpoint = sprintf(
      this.getEndpointForResource(id),
      this.getParameters(undefined, entity)
    );
    const { data } = await this.client.post<Single<PartialObject<T>>>(
      endpoint,
      this.prepareEntityForUpdate(entity)
    );
    return data;
  }

  async delete(
    id: number | (PartialObject<T> & { id: number }) | (T & { id: number }),
    parameters?: SimpleMapType
  ): Promise<void> {
    if (this.isReadOnly) {
      throw new ApiError('This operation is not supported');
    }
    const entityId = typeof id === 'number' ? id : id.id;
    const endpoint = sprintf(
      this.getEndpointForResource(entityId),
      this.getParameters(parameters, typeof id === 'object' ? id : undefined)
    );
    await this.client.delete(endpoint);
  }

  async find(
    id: number,
    parameters?: SimpleMapType
  ): Promise<PartialObject<T>> {
    const endpoint = sprintf(
      this.getEndpointForResource(id),
      this.getParameters(parameters)
    );
    const { data } = await this.client.get<Single<PartialObject<T>>>(endpoint);
    return data;
  }

  protected prepareQueryRequest(queryRequest: QueryRequest): MapType {
    const paginate = queryRequest.paginate ?? this.defaultPaginate;
    const sorting = queryRequest.sort ?? this.defaultSorting;
    const parametersMap: MapType = {
      order: Object.keys(sorting),
      order_direction: Object.values(sorting),
      page: queryRequest.page ?? this.defaultPage,
      per_page: paginate ? queryRequest.perPage ?? this.defaultPerPage : 0,
    };
    const { filter } = queryRequest;
    if (filter && has(filter, 'search')) {
      parametersMap.search = get(filter, 'search');
    }
    if (filter && has(filter, 'filter_by') && has(filter, 'filter_value')) {
      parametersMap.filter_by = get(filter, 'filter_by');
      parametersMap.filter_value = get(filter, 'filter_value');
    }
    if (filter && has(filter, 'filter')) {
      parametersMap.search = get(filter, 'filter');
    }
    return parametersMap;
  }

  async query(
    queryRequest?: QueryRequest,
    parameters?: SimpleMapType
  ): Promise<QueryResponse<T>> {
    const endpoint = sprintf(this.endpoint, this.getParameters(parameters));
    const params = this.prepareQueryRequest(queryRequest ?? {});
    const { data, meta } = await this.client.get<Collection<T>>(
      endpoint,
      params
    );
    return {
      data: Object.values(data),
      meta: {
        ...meta,
        query: queryRequest,
        parameters,
      },
    };
  }
}
