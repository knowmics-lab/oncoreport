/* eslint-disable @typescript-eslint/no-explicit-any,@typescript-eslint/ban-ts-comment */
import { container } from 'tsyringe';
import IdentifiableEntity from '../../interfaces/common/identifiableEntity';
import { Adapter } from '../../interfaces/adapter';

const fillablePropertyKey = Symbol.for('fillable');
const fillableWithEntityPropertyKey = Symbol.for('fillableWithEntity');
const userReadonlyPropertyKey = Symbol.for('userReadonly');

export function fillable() {
  return Reflect.metadata(fillablePropertyKey, true);
}

export function isFillable(target: any, propertyKey: string) {
  return Reflect.getMetadata(fillablePropertyKey, target, propertyKey) || false;
}

export function userReadonly() {
  return Reflect.metadata(userReadonlyPropertyKey, true);
}

export function isUserReadonly(target: any, propertyKey: string) {
  return (
    Reflect.getMetadata(userReadonlyPropertyKey, target, propertyKey) || false
  );
}

export function fillableWithEntity<T>(cls: T) {
  return Reflect.metadata(fillableWithEntityPropertyKey, cls);
}

export function getFillableWithEntity(target: any, propertyKey: string) {
  return Reflect.getMetadata(
    fillableWithEntityPropertyKey,
    target,
    propertyKey
  );
}

export default abstract class Entity<T extends IdentifiableEntity>
  implements IdentifiableEntity {
  private oId?: number;

  protected adapter: Adapter<T>;

  private isDeleted = false;

  protected constructor(adapter: Adapter<T>) {
    this.adapter = adapter;
  }

  protected get deleted() {
    return this.isDeleted;
  }

  public get id(): number | undefined {
    return this.oId;
  }

  public async delete(): Promise<this> {
    if (!this.isDeleted && this.oId) {
      await this.adapter.delete((this as unknown) as T);
    }
    this.isDeleted = true;
    return this;
  }

  public async save(): Promise<this> {
    if (this.isDeleted) throw new Error('Attempting to save deleted entity');
    let newData;
    if (this.oId) {
      newData = await this.adapter.update((this as unknown) as T);
    } else {
      newData = await this.adapter.create((this as unknown) as T);
    }
    return this.doFill(newData, true);
  }

  public async setId(newId: number): Promise<this> {
    if (this.isDeleted) throw new Error('Attempting to modify deleted entity');
    if (this.oId !== newId) {
      this.oId = newId;
      await this.refresh();
    }
    return this;
  }

  protected doFill(d: Partial<T>, internal: boolean): this {
    if (this.isDeleted) throw new Error('Attempting to fill deleted entity');
    let o: Partial<T> = {};
    // eslint-disable-next-line no-restricted-syntax
    for (const k of Object.keys(d)) {
      if (isFillable(this, k)) {
        if (internal || (!internal && !isUserReadonly(this, k))) {
          // @ts-ignore
          const objectData = d[k];
          const cls = getFillableWithEntity(this, k);
          if (cls && objectData) {
            o = ({
              ...o,
              [k]: (container.resolve(cls) as Entity<any>).doFill(
                objectData,
                true
              ),
            } as unknown) as Partial<T>;
          } else {
            o = {
              ...o,
              [k]: objectData,
            } as Partial<T>;
          }
        }
      }
    }
    Object.assign(this, o);
    if (internal) this.oId = d.id;
    return this;
  }

  public fill(d: Partial<T>): this {
    return this.doFill(d, false);
  }

  public async refresh(): Promise<this> {
    if (this.isDeleted) throw new Error('Attempting to refresh deleted entity');
    if (this.id) {
      const data = await this.adapter.fetchOne(this);
      this.doFill(data, true);
    }
    return this;
  }

  public fillFromCollection(d: T): this {
    return this.doFill(d, true);
  }
}
