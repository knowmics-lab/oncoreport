/* eslint-disable @typescript-eslint/no-explicit-any,class-methods-use-this */
import { InjectionToken, container } from 'tsyringe';
import { ignorePromise } from '../utils';
import {
  Arrayable,
  ExtendedPartialObject,
  MapValueType,
  PartialObject,
  PartialWithoutRelations,
} from '../interfaces/common';
import {
  EntityObject,
  EntityObserver,
  RepositoryObject,
} from '../interfaces/entity';

type Fillable<R> = number | R | PartialObject<R>;

export default class HasMany<R extends EntityObject>
  extends Array<R>
  implements EntityObserver<EntityObject>, Array<R>
{
  [index: number]: R;

  /**
   * An internal array of entities that will be saved after the referring object is created
   * @protected
   */
  protected willSaveOnCreate: R[] = [];

  /**
   * A repository object used for caching and entity building
   * @protected
   */
  protected repository!: RepositoryObject<R>;

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
    relatedRepositoryToken: InjectionToken<RepositoryObject<R>> | number,
    private referringObject: EntityObject,
    private foreignKey: keyof R | { [localKey: string]: keyof R },
    data: Fillable<R>[] = []
  ) {
    super();
    if (typeof relatedRepositoryToken !== 'number') {
      this.repository = container.resolve(relatedRepositoryToken);
      this.syncFill(data);
    }
  }

  /**
   * Undocumented - Do not use
   */
  public syncFill(data: Fillable<R>[]): this {
    Object.isExtensible(this);
    if (this.length > 0) {
      this.slice(0, this.length);
    }
    this.push(
      ...data.map((o) => {
        if (typeof o === 'number') {
          return this.repository.createStubEntity(o, this.getParameters());
        }
        if (typeof o === 'object' && o.isEntity && o.isEntity()) {
          return o as R;
        }
        return this.repository.createEntitySync(o, this.getParameters());
      })
    );
    return this;
  }

  /**
   * Create a new entity related to the parent object
   */
  public new(): R {
    if (this.repository.adapter.readonly)
      throw new Error(
        'Attempting to create a new object for a readonly entity'
      );
    const entity = this.repository.resolve().initializeNew();
    entity.observe(this.entityObserver);
    if (!this.referringObject.isNew) {
      this.fillForeignKey(entity);
    } else {
      this.willSaveOnCreate.push(entity);
    }
    super.push(entity);
    return entity;
  }

  /**
   * Create a new entity related to the parent object
   * @param data
   */
  public async create(
    data: ExtendedPartialObject<R, EntityObject>
  ): Promise<R> {
    if (this.repository.adapter.readonly)
      throw new Error(
        'Attempting to create a new object for a readonly entity'
      );
    const entity = this.repository.resolve().initializeNew();
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
    values: ExtendedPartialObject<R, EntityObject>
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
    attributes: ExtendedPartialObject<R, EntityObject>,
    values: ExtendedPartialObject<R, EntityObject>
  ): Promise<R> {
    const idx = this.findIndex((o) => {
      for (const [k, v] of Object.entries(attributes)) {
        const vFinal =
          typeof v === 'object' && v.isEntity && v.isEntity() ? v.id : v;
        const cmpWith: any = o[k as unknown as keyof R];
        const cmpWithFinal =
          typeof cmpWith === 'object' && cmpWith.isEntity && cmpWith.isEntity()
            ? cmpWith.id
            : cmpWith;
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
    attributes: ExtendedPartialObject<R, EntityObject>,
    values: ExtendedPartialObject<R, EntityObject>
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
   * Performs a query on this relationship
   */
  public query() {
    return this.repository.query(this.getParameters());
  }

  /**
   * Refresh this entity reloading all linked entities
   */
  public async refresh() {
    this.syncFill(
      (
        await this.repository.adapter.query(
          {
            perPage: 0,
          },
          this.getParameters()
        )
      ).data
    );
    return this;
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
  public toDataObject(
    fullyDump?: boolean
  ): (PartialWithoutRelations<R, EntityObject> | number)[] {
    return this.map((o) => (fullyDump ? o.toDataObject() : o.id));
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

  public reverse(): R[] {
    return [...this].reverse();
  }

  public map<U>(
    callbackfn: (value: R, index: number, array: R[]) => U,
    thisArg?: any
  ): U[] {
    return [...this].map(callbackfn, thisArg);
  }

  public filter<S extends R>(
    predicate: (value: R, index: number, array: R[]) => value is S,
    thisArg?: any
  ): S[] {
    return [...this].filter(predicate, thisArg);
  }

  public reduce(
    callbackfn: (
      previousValue: R,
      currentValue: R,
      currentIndex: number,
      array: R[]
    ) => R,
    initialValue?: any
  ): R {
    return [...this].reduce(callbackfn, initialValue);
  }

  public reduceRight(
    callbackfn: (
      previousValue: R,
      currentValue: R,
      currentIndex: number,
      array: R[]
    ) => R,
    initialValue?: any
  ): R {
    return [...this].reduceRight(callbackfn, initialValue);
  }

  public flatMap<U, This = undefined>(
    callback: (
      this: This,
      value: R,
      index: number,
      array: R[]
    ) => ReadonlyArray<U> | U,
    thisArg?: This
  ): U[] {
    return [...this].flatMap(callback, thisArg);
  }

  protected getParameters() {
    let params = {};
    if (typeof this.foreignKey === 'string') {
      params = {
        [this.foreignKey]: this.referringObject.id,
      };
    } else {
      for (const [localKey, foreignKey] of Object.entries(this.foreignKey)) {
        params = {
          ...params,
          [foreignKey]:
            localKey === 'id'
              ? this.referringObject.id
              : this.referringObject[localKey as keyof EntityObject],
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
