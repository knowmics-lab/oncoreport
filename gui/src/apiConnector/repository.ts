import { container, InjectionToken } from 'tsyringe';
import { get, has, set, unset } from 'lodash';
import Adapter from './httpClient/adapter';
import {
  ExtendedPartialObject,
  PartialObject,
  SimpleMapType,
} from './interfaces/common';
import QueryBuilder from './queryBuilder/queryBuilder';
import { ignorePromise } from './utils';
import {
  EntityObject,
  EntityObserver,
  QueryBuilderInterface,
} from './interfaces/entity';

type CacheArray<T> = { [id: number]: T };

export default abstract class Repository<E extends EntityObject> {
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
    protected _adapter: Adapter<E>,
    protected token: InjectionToken<E>
  ) {}

  public get adapter() {
    return this._adapter;
  }

  /**
   * Undocumented - Do not use
   */
  public resolve(id?: number): E {
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

  /**
   * Undocumented - Do not use
   */
  public createEntitySync(
    data?: PartialObject<E>,
    parameters?: SimpleMapType
  ): E {
    const id = data?.id;
    const entity = this.resolve(id);
    if (id && !entity.isInitialized) {
      entity.syncInitialize(data, parameters);
    } else if (id && entity.isInitialized) {
      entity.syncReinitialize(data, parameters);
    } else if (!id) {
      entity
        .initializeNew(parameters)
        .fill((data ?? {}) as ExtendedPartialObject<E, EntityObject>);
    }
    return entity;
  }

  /**
   * Undocumented - Do not use
   */
  public createStubEntity(id?: number, parameters?: SimpleMapType): E {
    const entity = this.resolve(id);
    if (id && !entity.isInitialized) {
      ignorePromise(entity.initialize(id, undefined, parameters));
    } else if (id) {
      ignorePromise(entity.refresh());
    } else {
      entity.initializeNew(parameters);
    }
    return entity;
  }

  /**
   * Undocumented - Do not use
   */
  public async createEntityAsync(
    id?: number,
    parameters?: SimpleMapType
  ): Promise<E> {
    const entity = this.resolve(id);
    if (id && !entity.isInitialized) {
      await entity.initialize(id, undefined, parameters);
    } else if (id) {
      await entity.refresh();
    } else {
      entity.initializeNew(parameters);
    }
    return entity;
  }

  public clear(): this {
    this.cache = {};
    return this;
  }

  public async new(data?: Partial<E>, parameters?: SimpleMapType): Promise<E> {
    if (this._adapter.readonly)
      throw new Error(
        'Attempting to create a new object for a readonly entity'
      );
    return this.createEntitySync(data, parameters);
  }

  public async create(
    data?: Partial<E>,
    parameters?: SimpleMapType
  ): Promise<E> {
    if (this._adapter.readonly)
      throw new Error(
        'Attempting to create a new object for a readonly entity'
      );
    return this.createEntitySync(data, parameters).save();
  }

  public async fetch(id: number, parameters?: SimpleMapType): Promise<E> {
    return this.createEntityAsync(id, parameters);
  }

  public query(parameters?: SimpleMapType): QueryBuilderInterface<E> {
    return new QueryBuilder<E>(this, parameters);
  }
}
