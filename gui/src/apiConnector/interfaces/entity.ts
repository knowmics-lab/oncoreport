/* eslint-disable @typescript-eslint/no-explicit-any */
import {
  ExtendedPartialObject,
  MapType,
  PartialObject,
  SimpleMapType,
} from './common';
import { Adapter } from './adapter';
import FilteringOperands from '../enums/filteringOperands';
import SortingDirection from '../enums/sortingDirection';
import { QueryRequest } from './queryRequest';

export interface EntityObject {
  readonly wasRecentlyCreated: boolean;
  readonly isInitialized: boolean;
  readonly isNew: boolean;
  id: number;
  isEntity(): this is EntityObject;
  observe(observer: EntityObserver<this>): this;
  removeObserver(o: EntityObserver<this>): this;
  syncInitialize(d: PartialObject<this>, parameters?: SimpleMapType): this;
  initializeNew(parameters?: SimpleMapType): this;
  fill(d: ExtendedPartialObject<this, EntityObject>): this;
  initialize(
    id: number,
    d?: PartialObject<this>,
    parameters?: SimpleMapType
  ): Promise<this>;
  refresh(): Promise<this>;
  save(): Promise<this>;
  serialize(): MapType;
  setParameters(parameters: SimpleMapType): this;
}

export interface ResultSetInterface<E extends EntityObject> extends Array<E> {
  readonly paginated: boolean;
  readonly currentPage: number;
  readonly lastPage: number;
  readonly perPage: number;
  readonly from: number;
  readonly to: number;
  readonly total: number;
  readonly query: QueryRequest | undefined;
  readonly parameters?: SimpleMapType;
  observe(o: ResultSetObserver<this>): this;
  removeObserver(o: ResultSetObserver<this>): this;
  refresh(): Promise<void>;
  first(): Promise<void>;
  previous(): Promise<void>;
  next(): Promise<void>;
  last(): Promise<void>;
  clone(): ResultSetInterface<E>;
}

export interface QueryBuilderInterface<E extends EntityObject> {
  search(search: string): this;
  filter(filter_by: keyof E | (keyof E)[], filter_value: string): this;
  where(by: keyof E, value: any, op?: FilteringOperands): this;
  doNotPaginate(): this;
  paginate(perPage?: number): this;
  orderBy(attribute: keyof E, direction?: SortingDirection | string): this;
  get(page?: number): Promise<ResultSetInterface<E>>;
  first(): Promise<E | undefined>;
}

export interface RepositoryObject<E extends EntityObject> {
  adapter: Adapter<E>;
  createEntitySync(data?: PartialObject<E>, parameters?: SimpleMapType): E;
  resolve(id?: number): E;
  createStubEntity(id?: number, parameters?: SimpleMapType): E;
  query(parameters?: SimpleMapType): QueryBuilderInterface<E>;
}

export interface EntityObserver<T extends EntityObject> {
  created?(entity: T): void;

  updated?(entity: T): void;

  deleted?(entity: T): void;

  refreshed?(entity: T): void;
}

export interface ResultSetObserver<R> {
  refreshing?(o: R): void;

  refreshed?(o: R): void;

  changingPage?(o: R): void;

  changedPage?(o: R): void;
}
