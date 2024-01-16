/* eslint-disable @typescript-eslint/no-explicit-any,class-methods-use-this,no-nested-ternary,no-use-before-define */
import dayjs from 'dayjs';
import { get, has, set } from 'lodash';
import { container, InjectionToken } from 'tsyringe';
import { Draft, produce } from 'immer';
import EntityError from '../../errors/EntityError';
import {
  ExtendedPartialObject,
  MapType,
  MapValueType,
  PartialObject,
  PartialWithoutRelations,
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
import { EntityObject, RepositoryObject } from '../interfaces/entity';

export interface EntityObserver<T extends Entity> {
  created?(entity: T): void;

  updated?(entity: T): void;

  deleted?(entity: T): void;

  refreshed?(entity: T): void;
}

type WeakEntityObserver<T extends Entity> = WeakRef<EntityObserver<T>>;

interface AnyRelation<E extends Entity> {
  type: RelationsType;
  repositoryToken: InjectionToken<RepositoryObject<E>>;
  noRecursionSave?: boolean;
  fullyDumpInFormObject?: boolean;
  dumpAsFormObject?: boolean;
}

export interface HasOneRelation<E extends Entity> extends AnyRelation<E> {
  type: RelationsType.ONE;
}

export interface HasManyRelation<E extends Entity> extends AnyRelation<E> {
  type: RelationsType.MANY;
  foreignKey: keyof E | { [localKey: string]: keyof E };
}

export type HasManyReadonlyRelation<E extends Entity> = {
  type: RelationsType.MANY_READONLY;
  repositoryToken: InjectionToken<RepositoryObject<E>>;
};

type CustomRelationConfig = {
  [fieldName: string | symbol]: Omit<
    AnyRelation<any>,
    'type' | 'repositoryToken'
  >;
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
  dumpIdWithFullObject?: boolean;
  nullable?: boolean;
  identifier?: boolean;
  number?: boolean;
  date?: boolean;
  leaveAsIs?: boolean;
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
    delete target[key];
    Object.defineProperty(target, key, {
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
            options.relation.foreignKey as any,
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
            if (options.date && draft[key] && !dayjs.isDayjs(draft[key])) {
              draft[key] = dayjs(draft[key]);
            }
          });
          if (this.data !== nextState) this.dirty = true;
          this.data = nextState;
        } else if (
          options.relation &&
          (typeof value === 'object' || typeof value === 'undefined')
        ) {
          const nextState = produce(this.data, (draft: Draft<any>) => {
            draft[key] = value;
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

  protected observers: WeakEntityObserver<this>[] = [];

  @field<number>({
    readonly: true,
    fillable: false,
    serialize: { serializable: false },
  })
  public id = -1;

  @field<dayjs.Dayjs>({
    fillable: false,
    date: true,
    readonly: true,
    serialize: { serializable: false },
  })
  public created_at = dayjs();

  @field<string>({
    fillable: false,
    readonly: true,
    serialize: { serializable: false },
  })
  public created_at_diff = '';

  @field<dayjs.Dayjs>({
    fillable: false,
    date: true,
    readonly: true,
    serialize: { serializable: false },
  })
  public updated_at = dayjs();

  @field<string>({
    fillable: false,
    readonly: true,
    serialize: { serializable: false },
  })
  public updated_at_diff = '';

  protected constructor(
    adapter: any,
    protected requestParameters?: SimpleMapType,
  ) {
    this.adapter = adapter;
  }

  /**
   * Set the parameters used for the API call. This is used to build the URL
   * @param parameters
   */
  public setParameters(parameters: SimpleMapType): this {
    this.requestParameters = parameters;
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
    this.requestParameters = parameters ?? {};
    return this;
  }

  /**
   * Undocumented - Do not use
   */
  public syncInitialize(
    d: PartialObject<this>,
    parameters?: SimpleMapType,
  ): this {
    if (this.initialized)
      throw new EntityError('Attempting to reinitialize an entity');
    this.fillDataArray(d);
    this.requestParameters = parameters ?? {};
    this.initialized = true;
    this.dirty = false;
    return this;
  }

  /**
   * Undocumented - Do not use
   */
  public syncReinitialize(
    d: PartialObject<this>,
    parameters?: SimpleMapType,
  ): this {
    this.fillDataArray(d);
    this.requestParameters = {
      ...this.requestParameters,
      ...(parameters ?? {}),
    };
    this.dirty = false;
    return this;
  }

  /**
   * Undocumented - Do not use
   */
  public async initialize(
    id: number,
    d?: PartialObject<this>,
    parameters?: SimpleMapType,
  ): Promise<this> {
    if (this.initialized)
      throw new EntityError('Attempting to reinitialize an entity');
    set(this.data, 'id', id);
    this.requestParameters = parameters ?? {};
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
    const serializedObjectsDirty = [
      ...getMetadataMap<SerializationConfig<any>>(SERIALIZE, this)
        .filter((value) => value.dumpFullObject)
        .keys(),
    ]
      .map((k) => this.data[k as unknown as keyof SimpleMapType])
      .map((o) => {
        if (o instanceof Entity) return o.isDirty;
        if (o instanceof HasMany) return o.some((v) => v.isDirty);
        if (o instanceof HasManyReadonly) return o.some((v) => v.isDirty);
        return false;
      })
      .some((v) => v);
    return this.dirty || serializedObjectsDirty;
  }

  /**
   * A boolean indicating whether this entity was recently saved
   */
  public get wasRecentlyCreated(): boolean {
    return this.recentlyCreated;
  }

  /**
   * Checks if this object is an entity
   */
  public isEntity(): this is EntityObject {
    return this instanceof Entity;
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
    if (this.isDirty) {
      return this.isNew ? this.create() : this.update();
    }
    return this;
  }

  /**
   * Fill this entity with new data
   * @param d a data object
   */
  public fill(d: ExtendedPartialObject<this, EntityObject>): this {
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
            this.resolveUserFilledRelationship(r, data, get(this.data, k)),
          );
        }
      } else {
        set(
          o,
          k,
          dates.includes(k)
            ? data !== undefined
              ? dayjs(data)
              : undefined
            : data,
        );
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
        await this.adapter.find(this.id, this.getParameters()),
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
   * Converts this entity to an object that can be used for Formik forms
   */
  public toFormObject(
    customRelations: CustomRelationConfig = {},
  ): PartialWithoutRelations<this, EntityObject> {
    const fillables = getMetadataArray<string>(FILLABLE, this);
    const relations = getMetadataMap<Relation<any>>(RELATIONS, this);
    const dates = getMetadataArray<string>(DATES, this);
    const data: any = Utils.filterByKey(this.data, (k) =>
      fillables.includes(`${k}`),
    );
    for (const f of dates) {
      const value = data[f];
      if (value && dayjs.isDayjs(value)) {
        data[f] = value.format('YYYY-MM-DD');
      }
    }
    const doNotTouch: string[] = [];
    for (const [f, r] of relations) {
      const config: Relation<any> = has(customRelations, f)
        ? {
            ...r,
            ...get(customRelations, f),
          }
        : r;
      data[f] = this.dumpRelation(f.toString(), config, doNotTouch);
    }
    for (const f of Object.keys(data).filter((d) => !doNotTouch.includes(d))) {
      data[f] = data[f] === undefined ? '' : data[f];
    }
    return data;
  }

  /**
   * Serializes this object
   */
  public serialize(): MapType {
    const serializables = getMetadataMap<SerializationConfig<any>>(
      SERIALIZE,
      this,
    );
    const result: MapType = {};
    for (const f of Object.keys(this.data)) {
      const config = serializables.get(f) ?? {};
      if (config.serializable ?? true) {
        result[config.serializedKey ?? f] = (
          config.serialize ?? this.defaultSerializer
        ).bind(this)(this.data[f], config);
      }
    }
    return result;
  }

  /**
   * Undocumented - do not use
   */
  public getParameters(): SimpleMapType {
    return {
      ...(this.requestParameters ?? {}),
      ...this,
    };
  }

  protected dumpHasOneRelation(
    fieldName: string,
    relation: HasOneRelation<any>,
    doNotTouch: string[],
  ) {
    const value = this.data[fieldName];
    if (relation.fullyDumpInFormObject) {
      doNotTouch.push(fieldName);
      let entity: Entity;
      if (value) {
        entity = <Entity>value;
      } else {
        entity = container.resolve(relation.repositoryToken).createEntitySync();
      }
      return relation.dumpAsFormObject ? entity.toFormObject() : entity;
    }
    return <number>get(value, 'id');
  }

  protected dumpHasManyRelation(
    fieldName: string,
    relation: HasManyRelation<any>,
  ) {
    const value = this.data[fieldName];
    if (value instanceof HasMany) {
      value.toFormObject(
        relation.fullyDumpInFormObject,
        relation.dumpAsFormObject,
      );
    }
    return [];
  }

  protected dumpHasManyReadonlyRelation(fieldName: string) {
    const value = this.data[fieldName];
    return value instanceof HasManyReadonly ? value.toFormObject() : [];
  }

  protected dumpRelation(
    fieldName: string,
    relation: Relation<any>,
    doNotTouch: string[],
  ) {
    if (relation.type === RelationsType.ONE) {
      return this.dumpHasOneRelation(fieldName, relation, doNotTouch);
    }
    if (relation.type === RelationsType.MANY) {
      return this.dumpHasManyRelation(fieldName, relation);
    }
    return this.dumpHasManyReadonlyRelation(fieldName);
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
          const related: Entity | HasMany<EntityObject> | undefined = this.data[
            f.toString()
          ] as unknown as any;
          if (related) {
            await related.save();
          }
        }
      }),
    );
    const newData = await this.adapter.update(this);
    this.fillDataArray(newData);
    this.recentlyCreated = false;
    this.dirty = false;
    this.updated();
    return this;
  }

  protected performNullableSerialization(
    value: any,
    config: SerializationConfig<any>,
  ) {
    if (config.identifier) {
      const number = +value;
      if (Number.isNaN(number) || number <= 0) return null;
    }
    if (
      config.number &&
      (Number.isNaN(+value) ||
        (typeof value === 'string' && value.trim().length === 0))
    ) {
      return null;
    }
    if (
      config.date &&
      (!value ||
        (typeof value === 'string' && value.trim().length === 0) ||
        !dayjs(value).isValid())
    ) {
      return null;
    }
    if (typeof value === 'string' && value.trim().length === 0) {
      return null;
    }
    if (typeof value === 'object' && !value) return null;
    if (typeof value === 'undefined') return null;
    return undefined;
  }

  protected performObjectSerialization(
    value: any,
    config: SerializationConfig<any>,
  ) {
    if (value instanceof Entity) {
      if (config.dumpFullObject) {
        const result = value.serialize();
        if (config.dumpIdWithFullObject) {
          result.id = +value.id > 0 ? +value.id : undefined;
        }
        return result;
      }
      if (value.id > 0) return value.id;
      return config.nullable ? null : undefined;
    }
    if (value instanceof HasMany) {
      if (config.nullable && value.length === 0) return null;
      return value.serialize(config.dumpFullObject);
    }
    if (value instanceof HasManyReadonly) {
      return value.serialize();
    }
    if (dayjs.isDayjs(value)) {
      return value.format('YYYY-MM-DD HH:mm:ss');
    }
    return undefined;
  }

  protected defaultSerializer(
    value: any,
    config: SerializationConfig<any>,
  ): MapValueType {
    if (config.leaveAsIs) return value;
    if (
      config.nullable &&
      this.performNullableSerialization(value, config) === null
    ) {
      return null;
    }
    if (config.date || value instanceof dayjs) {
      const dateValue = dayjs(value);
      if (!dateValue.isValid()) return undefined;
      return dateValue.format('YYYY-MM-DD HH:mm:ss');
    }
    if (config.number) {
      return +value;
    }
    if (config.identifier) {
      return +value > 0 ? +value : undefined;
    }
    if (typeof value === 'object') {
      return this.performObjectSerialization(value, config);
    }
    return value;
  }

  protected resolveRelationship<E extends Entity>(
    relation: Relation<E>,
    value: any,
    oldValue: any,
  ) {
    if (relation.type === RelationsType.ONE) {
      return container
        .resolve(relation.repositoryToken)
        .createEntitySync(value);
    }
    if (relation.type === RelationsType.MANY) {
      if (oldValue instanceof HasMany && Object.isExtensible(oldValue)) {
        return oldValue.syncFill(value);
      }
      return new HasMany(
        relation.repositoryToken,
        this,
        relation.foreignKey,
        value,
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
        let val: any = data[f as unknown as keyof typeof data];
        if (relations.has(f)) {
          const r = relations.get(f);
          if (r) {
            val = this.resolveRelationship(r, val, this.data[f] ?? undefined);
          }
        } else if (dates.includes(f)) {
          val = val ? dayjs(val) : undefined;
        }
        this.data = {
          ...this.data,
          [f]: !val ? undefined : val,
        };
      }
    }

    return this;
  }

  protected resolveUserFilledRelationship<E extends Entity>(
    relation: Relation<E>,
    value: any,
    oldValue: any,
  ) {
    if (relation.type === RelationsType.ONE) {
      const repository = container.resolve(relation.repositoryToken);
      if (typeof value === 'undefined') {
        return undefined;
      }
      if (typeof value === 'number' || typeof value === 'string') {
        const numberValue = +value;
        if (numberValue <= 0) return undefined;
        return repository.createStubEntity(numberValue);
      }
      if (typeof value === 'object') {
        if (value instanceof Entity) {
          return value;
        }
        if (oldValue instanceof Entity) {
          return oldValue.fill(value);
        }
        return repository.createEntitySync(value);
      }
    }
    if (relation.type === RelationsType.MANY) {
      if (oldValue instanceof HasMany && Object.isExtensible(oldValue)) {
        return oldValue.syncFill(value);
      }
      return new HasMany(
        relation.repositoryToken,
        this,
        relation.foreignKey,
        value,
      );
    }
    if (relation.type === RelationsType.MANY_READONLY) {
      if (oldValue instanceof HasMany && Object.isExtensible(oldValue)) {
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

  protected init() {
    for (const f of getMetadataArray(FIELDS, this)) {
      // @ts-ignore
      delete this[f];
    }
  }
}
