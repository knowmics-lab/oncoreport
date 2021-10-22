/* eslint-disable @typescript-eslint/no-explicit-any */
import Client from '../httpClient/client';
import { PartialObject, SimpleMapType } from './common';
import QueryResponse from './queryResponse';
import { QueryRequest } from './queryRequest';

export interface Adapter<T> {
  readonly client: Client;

  create(entity: PartialObject<T>): Promise<PartialObject<T>>;

  update(
    id: number | ((T | PartialObject<T>) & { id: number }),
    entity: PartialObject<T>
  ): Promise<PartialObject<T>>;

  delete(
    id: number | ((T | PartialObject<T>) & { id: number }),
    parameters?: SimpleMapType<any>
  ): Promise<void>;

  find(
    id: number | ((T | PartialObject<T>) & { id: number }),
    parameters?: SimpleMapType<any>
  ): Promise<PartialObject<T>>;

  query(
    queryRequest?: QueryRequest,
    parameters?: SimpleMapType<any>
  ): Promise<QueryResponse<T>>;
}
