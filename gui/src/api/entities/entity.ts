/* eslint-disable @typescript-eslint/no-explicit-any,@typescript-eslint/ban-ts-comment,no-restricted-syntax */
import { container, InjectionToken } from 'tsyringe';
import { get, has, set } from 'lodash';
import produce, { Draft } from 'immer';
import * as Immutable from 'immutable';
import { IdentifiableEntity, Adapter, SimpleMapType } from '../../interfaces';
import EntityError from '../../errors/EntityError';

const fillableKey = Symbol.for('fillable');
const withEntityKey = Symbol.for('withEntity');
const readonlyKey = Symbol.for('readonly');
const fieldsKey = Symbol.for('fields');

function addEntityToken(
  target: any,
  property: string | symbol,
  token: InjectionToken
) {
  const old = (Reflect.getMetadata(withEntityKey, target) ||
    Immutable.Map()) as Map<string | symbol, InjectionToken>;
  Reflect.defineMetadata(withEntityKey, old.set(property, token), target);
}

function getEntityTokens(target: any) {
  return (Reflect.getMetadata(withEntityKey, target) || Immutable.Map()) as Map<
    string | symbol,
    InjectionToken
  >;
}

function pushToArrayMeta(key: symbol, target: any, value: any) {
  const old = Reflect.getMetadata(key, target) || [];
  Reflect.defineMetadata(key, [...old, value], target);
}

function getArrayMeta<T>(key: symbol, target: any): T[] {
  return (Reflect.getMetadata(key, target) || []) as T[];
}

export type FieldOptions<T = any> = {
  fillable?: boolean;
  readonly?: boolean;
  withEntity?: InjectionToken<T>;
  getMutator?: (value: T) => any;
  setMutator?: (state: Draft<any>, next: T) => void;
};

export function field<T = any>(options: FieldOptions<T> = {}) {
  return (target: any, key: string | symbol) => {
    pushToArrayMeta(fieldsKey, target, key);
    if (options.fillable) {
      pushToArrayMeta(fillableKey, target, key);
    }
    if (options.readonly) {
      pushToArrayMeta(readonlyKey, target, key);
    }
    if (options.withEntity) {
      addEntityToken(target, key, options.withEntity);
    }
    return Object.defineProperty(target, key, {
      get() {
        const val = get(this.data, key);
        return options.getMutator ? options.getMutator(val) : val;
      },
      set(value: T) {
        if (!options.readonly) {
          const nextState = produce(this.data, (draft: Draft<any>) => {
            if (options.setMutator) {
              options.setMutator.call(this, draft, value);
            } else {
              draft[key] = value;
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

export enum EntityEvent {
  CREATE,
  UPDATE,
  DELETE,
}

type ListenerFunction<T> = (entity: T) => void;

export type NumberPartial<T> = {
  [P in keyof T]?: T[P] extends IdentifiableEntity ? number : T[P];
};

type Fillable<T> = Partial<T> | NumberPartial<T>;

export default abstract class Entity<T extends IdentifiableEntity>
  implements IdentifiableEntity
{
  protected data: SimpleMapType<any> = {};

  protected adapter: Adapter<T>;

  protected initialized = false;

  protected dirty = false;

  protected isDeleted = false;

  @field<number>({
    readonly: true,
    fillable: false,
  })
  public id?: number;

  protected listeners = new Map<EntityEvent, ListenerFunction<Entity<T>>[]>([
    [EntityEvent.CREATE, []],
    [EntityEvent.UPDATE, []],
    [EntityEvent.DELETE, []],
  ]);

  public constructor(adapter: Adapter<T>) {
    this.adapter = adapter;
  }

  public initializeNew(): this {
    if (this.initialized)
      throw new EntityError('Attempting to reinitialize an entity');
    this.initialized = true;
    this.dirty = true;
    return this;
  }

  public syncInitialize(d: T): this {
    if (this.initialized)
      throw new EntityError('Attempting to reinitialize an entity');
    this.fillDataArray(d);
    this.initialized = true;
    this.dirty = false;
    return this;
  }

  public async initialize(id?: number, d?: T): Promise<this> {
    if (this.initialized)
      throw new EntityError('Attempting to reinitialize an entity');
    set(this.data, 'id', id);
    if (d) {
      this.fillDataArray(d);
    } else if (id) {
      await this.refresh();
    }
    this.initialized = true;
    this.dirty = false;
    return this;
  }

  public get isNew(): boolean {
    return !has(this.data, 'id') || !get(this.data, 'id');
  }

  public get isDirty(): boolean {
    return this.dirty;
  }

  public async delete(): Promise<this> {
    if (!this.isDeleted && !this.isNew) {
      await this.adapter.delete(this as unknown as T);
      this.notify(EntityEvent.DELETE);
    }
    this.isDeleted = true;
    return this;
  }

  public async save(): Promise<this> {
    if (this.isDeleted) throw new Error('Attempting to save deleted entity');
    if (this.dirty) {
      let newData;
      if (this.isNew) {
        newData = await this.adapter.create(this as unknown as T);
        this.fillDataArray(newData);
        this.notify(EntityEvent.CREATE);
      } else {
        newData = await this.adapter.update(this as unknown as T);
        // console.log(newData);
        this.fillDataArray(newData);
        this.notify(EntityEvent.UPDATE);
      }
      this.dirty = false;
    }
    return this;
  }

  protected fillDataArray(d: Partial<T>): this {
    const fields = getArrayMeta(fieldsKey, this) as string[];
    const tokens = getEntityTokens(this);
    for (const f of fields) {
      if (has(d, f)) {
        let val = get(d, f);
        if (tokens.has(f)) {
          const t = tokens.get(f);
          if (t) {
            val = (container.resolve(t) as Entity<any>).syncInitialize(val);
          }
        }
        this.data = {
          ...this.data,
          [f]: val,
        };
      }
    }

    return this;
  }

  public fill(d: Fillable<T>): this {
    if (this.isDeleted) throw new Error('Attempting to fill deleted entity');
    const o: Partial<T> = {};
    const fillables = getArrayMeta(fillableKey, this) as string[];
    const tokens = getEntityTokens(this);
    const fields = Object.keys(d).filter((f) => fillables.includes(f));

    for (const k of fields) {
      const data = get(d, k);
      if (tokens.has(k)) {
        const t = tokens.get(k);
        if (t) {
          let obj = container.resolve(t) as Entity<any>;
          if (typeof data === 'number' || typeof data === 'string') {
            obj
              .initialize(+data)
              .then((r) => {
                return r;
              })
              .catch((e) => {
                throw e;
              });
          } else if (
            typeof data === 'object' &&
            data.constructor === obj.constructor
          ) {
            obj = data;
          } else if (
            typeof data === 'object' &&
            data.constructor !== obj.constructor
          ) {
            obj = obj.syncInitialize(data);
          }
          set(o, k, obj);
        }
      } else {
        set(o, k, data);
      }
    }

    Object.assign(this, o);
    return this;
  }

  public async refresh(): Promise<this> {
    if (this.isDeleted) throw new Error('Attempting to refresh deleted entity');
    if (!this.isNew) {
      this.fillDataArray(await this.adapter.fetchOne(this));
      this.dirty = false;
    }
    return this;
  }

  public listen(e: EntityEvent, f: ListenerFunction<Entity<T>>): this {
    this.listeners.get(e)?.push(f);
    return this;
  }

  protected notify(e: EntityEvent): this {
    this.listeners.get(e)?.forEach((l) => l(this));
    return this;
  }

  public toDataObject(): NumberPartial<T> {
    const fillables = getArrayMeta(fillableKey, this) as string[];
    const tokens = getEntityTokens(this);
    const data: NumberPartial<T> = {};
    for (const f of fillables) {
      set(data, f, get(this.data, tokens.has(f) ? `${f}.id` : f, ''));
    }
    return data;
  }
}
