/* eslint-disable @typescript-eslint/no-explicit-any,class-methods-use-this */
import dayjs from 'dayjs';
import { get, has, set } from 'lodash';
import { container, InjectionToken } from 'tsyringe';
import produce, { Draft } from 'immer';
import EntityError from '../../errors/EntityError';
import {
  MapType,
  MapValueType,
  PartialObject,
  SimpleMapType,
} from '../interfaces/common';
import Adapter from '../httpClient/adapter';
import RelationsType from '../enums/relationsType';
import {
  getMetadataArray,
  getMetadataMap,
  pushToMetadataArray,
  pushToMetadataMap,
} from './classMetadataUtils';
import { Utils } from '../../api';
import HasMany from '../relations/hasMany';
import { HasManyReadonly } from '../index';
import Repository from '../repository';

type EntityOrType<T> = T extends Entity ? number : T;
type EntityArrayOrType<T> = T extends Array<Entity> ? number[] : T;

export type PartialWithoutRelations<T> = {
  -readonly [p in keyof T]?: EntityOrType<EntityArrayOrType<T[p]>>;
};

type EntityAndType<T> = T extends Entity ? number | T : T;
type EntityArrayAndType<T> = T extends Array<Entity> ? number[] | T : T;

export type ExtendedPartialObject<T> = {
  -readonly [p in keyof T]?: EntityArrayAndType<EntityAndType<T[p]>>;
};

export interface EntityObserver<T extends Entity> {
  created?(entity: T): void;

  updated?(entity: T): void;

  deleted?(entity: T): void;

  refreshed?(entity: T): void;
}

type WeakEntityObserver<T extends Entity> = WeakRef<EntityObserver<T>>;

export type HasOneRelation<E extends Entity> = {
  type: RelationsType.ONE;
  repositoryToken: InjectionToken<Repository<E>>;
  noRecursionSave?: boolean;
};

export type HasManyRelation<E extends Entity> = {
  type: RelationsType.MANY;
  repositoryToken: InjectionToken<Repository<E>>;
  noRecursionSave?: boolean;
  foreignKey: keyof E | { [localKey: string]: keyof E };
};

export type HasManyReadonlyRelation<E extends Entity> = {
  type: RelationsType.MANY_READONLY;
  repositoryToken: InjectionToken<Repository<E>>;
};

export type Relation<E extends Entity> =
  | HasOneRelation<E>
  | HasManyRelation<E>
  | HasManyReadonlyRelation<E>;

export type SerializationConfig<T> = {
  serializable?: boolean;
  serialize?: (value: T, config: SerializationConfig<T>) => MapValueType;
  serializedKey?: string;
  dumpFullObject?: boolean;
};

export type FieldOptions<T = any> = {
  fillable?: boolean;
  readonly?: boolean;
  date?: boolean;
  relation?: T extends Entity ? Relation<T> : undefined;
  serialize?: SerializationConfig<T>;
};

export const FILLABLE = Symbol.for('fillable');
export const READONLY = Symbol.for('readonly');
export const FIELDS = Symbol.for('fields');
export const DATES = Symbol.for('dates');
export const RELATIONS = Symbol.for('relations');
export const SERIALIZE = Symbol.for('serialize');

export function field<T = any>(options: FieldOptions<T> = {}) {
  return (target: any, key: string | symbol) => {
    pushToMetadataArray(FIELDS, target, key);
    if (options.fillable) pushToMetadataArray(FILLABLE, target, key);
    if (options.readonly) pushToMetadataArray(READONLY, target, key);
    if (options.date) pushToMetadataArray(DATES, target, key);
    if (options.relation)
      pushToMetadataMap(RELATIONS, target, key, options.relation);
    if (options.serialize)
      pushToMetadataMap(SERIALIZE, target, key, options.serialize);

    return Object.defineProperty(target, key, {
      get() {
        let value = get(this.data, key);
        if (
          options.relation &&
          options.relation.type === RelationsType.MANY &&
          typeof value === 'undefined'
        ) {
          value = new HasMany(
            options.relation.repositoryToken,
            this,
            options.relation.foreignKey as any
          );
          set(this.data, key, value);
        }
        if (
          options.relation &&
          options.relation.type === RelationsType.MANY_READONLY &&
          typeof value === 'undefined'
        ) {
          value = new HasManyReadonly(options.relation.repositoryToken, this);
          set(this.data, key, value);
        }
        return value;
      },
      set(value: T) {
        if (!options.readonly && !options.relation) {
          const nextState = produce(this.data, (draft: Draft<any>) => {
            draft[key] = value;
            if (options.date && !dayjs.isDayjs(draft[key])) {
              draft[key] = dayjs(draft[key]);
            }
          });
          if (this.data !== nextState) this.dirty = true;
          this.data = nextState;
        }
      },
      enumerable: true,
      configurable: true,
    });
  };
}

export default abstract class Entity {
  protected data: SimpleMapType = {};

  protected initialized = false;

  protected dirty = false;

  protected isDeleted = false;

  protected recentlyCreated = false;

  protected adapter: Adapter<this>;

  protected observers = new Array<WeakEntityObserver<this>>();

  @field<number>({
    readonly: true,
    fillable: false,
  })
  public id = -1;

  @field<dayjs.Dayjs>({
    fillable: false,
    date: true,
    readonly: true,
  })
  public created_at = dayjs();

  @field<string>({
    fillable: false,
    readonly: true,
  })
  public created_at_diff = '';

  @field<dayjs.Dayjs>({
    fillable: false,
    date: true,
    readonly: true,
  })
  public updated_at = dayjs();

  @field<string>({
    fillable: false,
    readonly: true,
  })
  public updated_at_diff = '';

  protected constructor(adapter: any, protected parameters?: SimpleMapType) {
    this.adapter = adapter;
  }

  /**
   * Set the parameters used for the API call. This is used to build the URL
   * @param parameters
   */
  public setParameters(parameters: SimpleMapType): this {
    this.parameters = parameters;
    return this;
  }

  /**
   * Undocumented - Do not use
   */
  public initializeNew(parameters?: SimpleMapType): this {
    if (this.initialized)
      throw new EntityError('Attempting to reinitialize an entity');
    this.initialized = true;
    this.dirty = true;
    this.data = {
      id: -1,
      created_at: dayjs(),
      updated_at: dayjs(),
    };
    this.parameters = parameters ?? {};
    return this;
  }

  /**
   * Undocumented - Do not use
   */
  public syncInitialize(
    d: PartialObject<this>,
    parameters?: SimpleMapType
  ): this {
    if (this.initialized)
      throw new EntityError('Attempting to reinitialize an entity');
    this.fillDataArray(d);
    this.parameters = parameters ?? {};
    this.initialized = true;
    this.dirty = false;
    return this;
  }

  /**
   * Undocumented - Do not use
   */
  public async initialize(
    id: number,
    d?: PartialObject<this>,
    parameters?: SimpleMapType
  ): Promise<this> {
    if (this.initialized)
      throw new EntityError('Attempting to reinitialize an entity');
    set(this.data, 'id', id);
    this.parameters = parameters ?? {};
    if (d) {
      this.fillDataArray(d);
    } else if (id > 0) {
      await this.refresh();
    }
    this.initialized = true;
    this.dirty = false;
    return this;
  }

  /**
   * A boolean indicating whether this entity has been saved or is new.
   * A new entity does not have a valid identifier.
   */
  public get isNew(): boolean {
    return !has(this.data, 'id') || get(this.data, 'id') <= 0;
  }

  /**
   * A boolean indicating whether this entity has been initialized
   */
  public get isInitialized(): boolean {
    return this.initialized;
  }

  /**
   * A boolean indicating whether this entity data have been modified
   */
  public get isDirty(): boolean {
    return this.dirty;
  }

  /**
   * A boolean indicating whether this entity was recently saved
   */
  public get wasRecentlyCreated(): boolean {
    return this.recentlyCreated;
  }

  /**
   * Delete this entity
   */
  public async delete(): Promise<void> {
    if (this.adapter.readonly)
      throw new Error('Attempting to delete a readonly entity');
    if (!this.isDeleted && !this.isNew) {
      await this.adapter.delete(this);
      this.deleted();
    }
    this.isDeleted = true;
  }

  /**
   * Save this entity. If the entity is new, related objects must
   * be added only after the first save call. However, some properties might have
   * a different behaviour.
   */
  public async save(): Promise<this> {
    if (this.adapter.readonly)
      throw new Error('Attempting to save a readonly entity');
    if (this.isDeleted) throw new Error('Attempting to save deleted entity');
    if (this.dirty) {
      return this.isNew ? this.create() : this.update();
    }
    return this;
  }

  /**
   * Fill this entity with new data
   * @param d a data object
   */
  public fill(d: ExtendedPartialObject<this>): this {
    if (this.isDeleted) throw new Error('Attempting to fill deleted entity');
    const o: PartialObject<this> = {};
    const fillables = getMetadataArray<string>(FILLABLE, this);
    const relations = getMetadataMap<Relation<any>>(RELATIONS, this);
    const dates = getMetadataArray<string>(DATES, this);
    const fields = Object.keys(d).filter((f) => fillables.includes(f));

    for (const k of fields) {
      const data = get(d, k);
      if (relations.has(k)) {
        const r = relations.get(k);
        if (r) {
          set(
            o,
            k,
            this.resolveUserFilledRelationship(r, data, get(this.data, k))
          );
        }
      } else {
        set(o, k, dates.includes(k) ? dayjs(data) : data);
      }
    }

    Object.assign(this, o);
    return this;
  }

  /**
   * Reload this entity
   */
  public async refresh(): Promise<this> {
    if (this.isDeleted) throw new Error('Attempting to refresh deleted entity');
    if (!this.isNew) {
      this.fillDataArray(
        await this.adapter.find(this.id, this.getParameters())
      );
      this.dirty = false;
      this.refreshed();
    }
    return this;
  }

  /**
   * Informs this object that another class wants to listen to the events
   * @param o
   */
  public observe(o: EntityObserver<this>): this {
    this.observers.push(new WeakRef<typeof o>(o));
    return this;
  }

  /**
   * Remove an observer from this object
   * @param o
   */
  public removeObserver(o: EntityObserver<this>): this {
    this.observers = this.observers.filter((o1) => o1.deref() !== o);
    return this;
  }

  /**
   * Converts this entity to an objects where related entities are converted to identifiers
   */
  public toDataObject(): PartialWithoutRelations<this> {
    const fillables = getMetadataArray<string>(FILLABLE, this);
    const relations = getMetadataMap<Relation<any>>(RELATIONS, this);
    const data: any = Utils.filterByKey(this.data, (k) =>
      fillables.includes(`${k}`)
    );
    for (const [f, r] of relations) {
      if (r.type === RelationsType.ONE) {
        data[f] = get(data[f], 'id');
      } else if (r.type === RelationsType.MANY) {
        const value = data[f];
        data[f] = value instanceof HasMany ? value.toDataObject() : [];
      }
    }
    return data;
  }

  /**
   * Serializes this object
   */
  public serialize(): MapType {
    const serializables = getMetadataMap<SerializationConfig<any>>(
      SERIALIZE,
      this
    );
    const result: MapType = {};
    for (const f of Object.keys(this.data)) {
      const config = serializables.get(f) ?? {};
      if (config.serializable ?? true) {
        result[config.serializedKey ?? f] = (
          config.serialize ?? this.defaultSerializer
        )(this.data[f], config);
      }
    }
    return result;
  }

  /**
   * Undocumented - do not use
   */
  public getParameters(): SimpleMapType {
    return {
      ...(this.parameters ?? {}),
      ...this,
    };
  }

  protected async create(): Promise<this> {
    const newData = await this.adapter.create(this);
    this.fillDataArray(newData);
    this.recentlyCreated = true;
    this.dirty = false;
    this.created();
    return this;
  }

  protected async update(): Promise<this> {
    const relations = getMetadataMap<Relation<any>>(RELATIONS, this);
    await Promise.all(
      relations.map(async (specs, f) => {
        if (
          specs.type !== RelationsType.MANY_READONLY &&
          !specs.noRecursionSave
        ) {
          const related: Entity | HasMany | undefined = this.data[
            f.toString()
          ] as unknown as any;
          if (related) {
            await related.save();
          }
        }
      })
    );
    const newData = await this.adapter.update(this);
    this.fillDataArray(newData);
    this.recentlyCreated = false;
    this.dirty = false;
    this.updated();
    return this;
  }

  protected defaultSerializer(
    value: any,
    config: SerializationConfig<any>
  ): MapValueType {
    if (value instanceof Entity)
      return config.dumpFullObject ? value.serialize() : value.id;
    if (value instanceof dayjs.Dayjs && dayjs.isDayjs(value)) {
      return value.format('YYYY-MM-DD HH:mm:ss');
    }
    if (value instanceof HasMany) return value.serialize(config.dumpFullObject);
    if (value instanceof HasManyReadonly) return value.serialize();
    return value;
  }

  protected resolveRelationship<E extends Entity>(
    relation: Relation<E>,
    value: any,
    oldValue: any
  ) {
    if (relation.type === RelationsType.ONE) {
      return container
        .resolve(relation.repositoryToken)
        .createEntitySync(value);
    }
    if (relation.type === RelationsType.MANY) {
      if (oldValue instanceof HasMany) {
        return oldValue.syncFill(value);
      }
      return new HasMany(
        relation.repositoryToken,
        this,
        relation.foreignKey,
        value
      );
    }
    if (relation.type === RelationsType.MANY_READONLY) {
      if (oldValue instanceof HasMany) {
        return oldValue.syncFill(value);
      }
      return new HasManyReadonly(relation.repositoryToken, value);
    }
    return undefined;
  }

  protected fillDataArray(data: PartialObject<this>): this {
    const fields = getMetadataArray<string>(FIELDS, this);
    const relations = getMetadataMap<Relation<any>>(RELATIONS, this);
    const dates = getMetadataArray<string>(DATES, this);
    for (const f of fields) {
      if (has(data, f)) {
        let val = get(data, f);
        if (relations.has(f)) {
          const r = relations.get(f);
          if (r) {
            val = this.resolveRelationship(r, val, this.data[f] ?? undefined);
          }
        } else if (dates.includes(f)) {
          val = dayjs(val);
        }
        this.data = {
          ...this.data,
          [f]: val,
        };
      }
    }

    return this;
  }

  protected resolveUserFilledRelationship<E extends Entity>(
    relation: Relation<E>,
    value: any,
    oldValue: any
  ) {
    if (relation.type === RelationsType.ONE) {
      const repository = container.resolve(relation.repositoryToken);
      if (typeof value === 'number') {
        return repository.createStubEntity(value);
      }
      if (typeof value === 'object') {
        if (value instanceof Entity) {
          return value;
        }
        return repository.createEntitySync(value);
      }
    }
    if (relation.type === RelationsType.MANY) {
      if (oldValue instanceof HasMany) {
        return oldValue.syncFill(value);
      }
      return new HasMany(
        relation.repositoryToken,
        this,
        relation.foreignKey,
        value
      );
    }
    if (relation.type === RelationsType.MANY_READONLY) {
      if (oldValue instanceof HasMany) {
        return oldValue.syncFill(value);
      }
      return new HasManyReadonly(relation.repositoryToken, value);
    }
    return undefined;
  }

  protected created() {
    this.observers.forEach((ref) => {
      const o = ref.deref();
      if (o && o.created) o.created(this);
    });
  }

  protected updated() {
    this.observers.forEach((ref) => {
      const o = ref.deref();
      if (o && o.updated) o.updated(this);
    });
  }

  protected deleted() {
    this.observers.forEach((ref) => {
      const o = ref.deref();
      if (o && o.deleted) o.deleted(this);
    });
  }

  protected refreshed() {
    this.observers.forEach((ref) => {
      const o = ref.deref();
      if (o && o.refreshed) o.refreshed(this);
    });
  }
}
