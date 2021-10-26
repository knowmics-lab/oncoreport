/* eslint-disable import/no-cycle */
import { InjectionToken, container } from 'tsyringe';
import Entity from '../entity/entity';
import { Arrayable, MapValueType, PartialObject } from '../interfaces/common';
import Repository from '../repository';

type Fillable<R> = number | R | PartialObject<R>;

export default class HasManyReadonly<
  R extends Entity = Entity
> extends Array<R> {
  /**
   * A repository object used for caching and entity building
   * @protected
   */
  protected repository: Repository<R>;

  constructor(
    relatedRepositoryToken: InjectionToken<Repository<R>>,
    data: Fillable<R>[] = []
  ) {
    super();
    this.repository = container.resolve(relatedRepositoryToken);
    this.syncFill(data);
  }

  /**
   * Undocumented - Do not use
   */
  public syncFill(data: Fillable<R>[]): this {
    if (this.length > 0) {
      this.slice(0, this.length);
    }
    this.push(
      ...data.map((o) => {
        if (typeof o === 'number') {
          return this.repository.createStubEntity(o);
        }
        if (o instanceof Entity) {
          return o as R;
        }
        return this.repository.createEntitySync(o);
      })
    );
    return this;
  }

  /**
   * Attach an entity to this relationship
   * @param entities
   */
  public attach(entities: Arrayable<R>): void {
    super.push(...(Array.isArray(entities) ? entities : [entities]));
  }

  /**
   * Convert this object to a list of identifiers
   */
  public toDataObject(): number[] {
    return this.map((o) => o.id);
  }

  /**
   * Serializes this object.
   */
  public serialize(): MapValueType {
    return this.map((o) => o.id);
  }
}
