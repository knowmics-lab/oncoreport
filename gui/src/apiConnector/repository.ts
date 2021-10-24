/* eslint-disable import/no-cycle */
import { container, InjectionToken } from 'tsyringe';
import { get, has, set, unset } from 'lodash';
import Entity, { EntityObserver, ExtendedPartialObject } from './entity/entity';
import Adapter from './httpClient/adapter';
import { PartialObject, SimpleMapType } from './interfaces/common';
import QueryBuilder from './queryBuilder/queryBuilder';

type CacheArray<T> = { [id: number]: T };

export default abstract class Repository<E extends Entity> {
  protected cache: CacheArray<WeakRef<E>> = {};

  protected entityObserver: EntityObserver<E> = {
    created: (entity: E) => {
      if (entity.wasRecentlyCreated) {
        set(this.cache, entity.id, new WeakRef(entity));
      }
    },
    deleted: (entity: E) => {
      if (has(this.cache, entity.id)) {
        unset(this.cache, entity.id);
      }
    },
  };

  protected constructor(
    public parameters: SimpleMapType,
    protected _adapter: Adapter<E>,
    protected token: InjectionToken<E>
  ) {}

  public get adapter() {
    return this._adapter;
  }

  protected resolveMaybeCached(id?: number): E {
    if (id && has(this.cache, id)) {
      const entity = get(this.cache, id).deref();
      if (entity) return entity;
    }
    const newEntity = container
      .resolve(this.token)
      .observe(this.entityObserver);
    if (id) set(this.cache, id, new WeakRef(newEntity));
    return newEntity;
  }

  public createEntitySync(data?: PartialObject<E>): E {
    const id = data?.id;
    const entity = this.resolveMaybeCached(id);
    if (id && !entity.isInitialized) {
      entity.syncInitialize(data, this.parameters);
    } else {
      entity
        .initializeNew(this.parameters)
        .fill((data ?? {}) as ExtendedPartialObject<E>);
    }
    return entity;
  }

  public async createEntityAsync(id?: number): Promise<E> {
    const entity = this.resolveMaybeCached(id);
    if (id && !entity.isInitialized) {
      await entity.initialize(id, undefined, this.parameters);
    } else if (id) {
      await entity.refresh();
    } else {
      entity.initializeNew(this.parameters);
    }
    return entity;
  }

  public clear(): this {
    this.cache = {};
    return this;
  }

  public async create(data?: Partial<E>): Promise<E> {
    return this.createEntitySync(data).save();
  }

  public async fetch(id: number): Promise<E> {
    return this.createEntityAsync(id);
  }

  public query(): QueryBuilder<E> {
    return new QueryBuilder<E>(this);
  }
}
