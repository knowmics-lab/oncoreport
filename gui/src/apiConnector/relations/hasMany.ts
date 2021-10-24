/* eslint-disable @typescript-eslint/no-explicit-any,class-methods-use-this,import/no-cycle */
import { InjectionToken, container } from 'tsyringe';
import Entity, {
  EntityObserver,
  ExtendedPartialObject,
} from '../entity/entity';
import { ignorePromise } from '../utils';
import { Arrayable, MapValueType, PartialObject } from '../interfaces/common';

type Fillable<R> = number | R | PartialObject<R>;

export default class HasMany<
    R extends Entity = Entity,
    T extends Entity = Entity
  >
  extends Array<R>
  implements EntityObserver<T>
{
  /**
   * An internal array of entities that will be saved after the referring object is created
   * @protected
   */
  protected willSaveOnCreate: R[] = [];

  /**
   * An observer object used to listen to changes in the related objects
   * @protected
   */
  protected entityObserver: EntityObserver<R> = {
    deleted: (entity: R) => {
      const idx = this.indexOf(entity);
      if (idx >= 0) {
        this.splice(idx, 1);
      }
    },
  };

  constructor(
    private relatedToken: InjectionToken<R>,
    private referringObject: T,
    private foreignKey: keyof R | { [localKey: string]: keyof R },
    data: Fillable<R>[] = []
  ) {
    super();
    this.syncFill(data);
  }

  public syncFill(data: Fillable<R>[]): this {
    if (this.length > 0) {
      this.slice(0, this.length);
    }
    this.push(
      ...data.map((o) => {
        const obj = container.resolve(this.relatedToken);
        if (typeof o === 'number') {
          ignorePromise(obj.initialize(o, this.getParameters()));
        } else if (o instanceof Entity) {
          return o as R;
        } else {
          obj.syncInitialize(o, this.getParameters());
        }
        return obj;
      })
    );
    return this;
  }

  /**
   * Create a new entity related to the parent object
   * @param data
   */
  public async create(data: ExtendedPartialObject<R>): Promise<R> {
    const entity = container.resolve(this.relatedToken);
    entity.fill(data).observe(this.entityObserver);
    if (!this.referringObject.isNew) {
      this.fillForeignKey(entity);
      await entity.save();
    } else {
      this.willSaveOnCreate.push(entity);
    }
    super.push(entity);
    return entity;
  }

  /**
   * Find a related entity by its id or create a new entity with the provided values
   * @param id the identifier of the entity
   * @param values the values
   */
  public async findOrCreate(
    id: number,
    values: ExtendedPartialObject<R>
  ): Promise<R> {
    const idx = this.findIndex((o) => o.id === id);
    if (idx <= 0) return this.create(values);
    return this[idx];
  }

  /**
   * Find a linked entity by some of its attributes or create a new one
   * @param attributes a map of attributes
   * @param values the values
   */
  public async firstOrCreate(
    attributes: ExtendedPartialObject<R>,
    values: ExtendedPartialObject<R>
  ): Promise<R> {
    const idx = this.findIndex((o) => {
      for (const [k, v] of Object.entries(attributes)) {
        const vFinal = v instanceof Entity ? v.id : v;
        const cmpWith = o[k as unknown as keyof R];
        const cmpWithFinal = cmpWith instanceof Entity ? cmpWith.id : cmpWith;
        if (vFinal !== cmpWithFinal) return false;
      }
      return true;
    });
    if (idx <= 0)
      return this.create({
        ...attributes,
        ...values,
      });
    return this[idx];
  }

  /**
   * Find a linked entity by its attributes and updates its content with the values.
   * A new entity is created if no entity is found.
   * @param attributes
   * @param values
   */
  public async updateOrCreate(
    attributes: ExtendedPartialObject<R>,
    values: ExtendedPartialObject<R>
  ): Promise<R> {
    const o = await this.firstOrCreate(attributes, values);
    if (!o.wasRecentlyCreated) {
      await o.fill(values).save();
    }
    return o;
  }

  /**
   * Attach an entity to this relationship
   * @param entities
   */
  public attach(entities: Arrayable<R>): void {
    const entityArray = Array.isArray(entities) ? entities : [entities];
    if (this.referringObject.isNew) {
      super.push(...entityArray);
      this.willSaveOnCreate.push(...entityArray);
    } else {
      super.push(...entityArray.map((e) => this.fillForeignKey(e)));
    }
  }

  /**
   * Saves all entities in this object
   */
  public async save(): Promise<void> {
    await Promise.all(this.map((o) => o.save()));
  }

  /**
   * Appends new entities to the end of this array, and returns the new length of the array.
   * @param items New entities to add to the array.
   */
  public push(...items: R[]): number {
    this.attach(items);
    return this.length;
  }

  /**
   * Inserts new entities at the start of this array, and returns the new length of the array.
   * @param items Entities to insert at the start of the array.
   */
  public unshift(...items: R[]): number {
    if (this.referringObject.isNew) {
      this.willSaveOnCreate.push(...items);
      return super.unshift(...items);
    }
    return super.unshift(...items.map((e) => this.fillForeignKey(e)));
  }

  /**
   * Convert this object to a list of identifiers
   */
  public toDataObject(): number[] {
    return this.map((o) => o.id);
  }

  /**
   * Serializes this object. If dumpFullObject is true the related entities will be recursively serialized.
   * Otherwise only the ids will be dumped.
   * @param dumpFullObject
   */
  public serialize(dumpFullObject = false): MapValueType {
    return this.map((o) => (dumpFullObject ? o.serialize() : o.id));
  }

  /**
   * Undocumented - Do not use
   */
  public created(): void {
    this.willSaveOnCreate.forEach((e) => {
      this.fillForeignKey(e);
      ignorePromise(e.save());
    });
    this.willSaveOnCreate = [];
  }

  protected getParameters() {
    let params = {};
    if (typeof this.foreignKey === 'string') {
      params = {
        [this.foreignKey]: this.referringObject,
      };
    } else {
      for (const [localKey, foreignKey] of Object.entries(this.foreignKey)) {
        params = {
          ...params,
          [foreignKey]:
            localKey === 'id'
              ? this.referringObject
              : this.referringObject[localKey as keyof T],
        };
      }
    }
    return params;
  }

  protected fillForeignKey(entity: R): R {
    const params = this.getParameters();
    return entity.setParameters(params).fill(params);
  }
}
