import { container, InjectionToken } from 'tsyringe';
import { Adapter, Arrayable, Entity as IEntity, EntityArray as IEntityArray } from '../../interfaces';
import Entity, { EntityEvent } from '../entities/entity';

export default class EntityArray<
    P extends IEntity,
    T extends IEntity,
    PO extends Entity<P>,
    TO extends Entity<T>
  >
  extends Array<TO>
  implements IEntityArray<TO>
{
  private loaded = false;

  private isNew: boolean;

  private willChangeOnSave: TO[] = [];

  get isLoaded(): boolean {
    return this.loaded;
  }

  constructor(
    private parentEntity: PO,
    private foreignKey: keyof TO,
    private adapter: Adapter<T>,
    private entityToken: InjectionToken<TO>
  ) {
    super();
    this.isNew = parentEntity.id <= 0;
    parentEntity.listen(EntityEvent.CREATE, (e) => {
      if (this.isNew) {
        this.isNew = false;

      }
    });
  }

  attach(entities: Arrayable<TO>): void {
    const entityArray = Array.isArray(entities) ? entities : [entities];
    this.push(
      ...entityArray.map((e) => {
        e[this.foreignKey] = this.parentEntity.id as unknown as TO[keyof TO];
        return e;
      })
    );
    if (this.isNew) {
      this.willChangeOnSave.push(...entityArray);
    }
  }

  async create(data: Partial<TO>): Promise<TO> {
    const entity = container.resolve(this.entityToken);
    entity.fill(data as unknown as T);
    entity[this.foreignKey] = this.parentEntity.id as unknown as TO[keyof TO];
    if (this.isNew) {
      this.willChangeOnSave.push(entity);
    } else {
      await entity.save();
    }

    return entity;
  }

  async delete(id: number): Promise<void> {
    this.willChangeOnSave = this.willChangeOnSave.filter((o) => o.id !== id);
    const idx = this.findIndex((o) => o.id === id);
    if (idx >= 0) {
      const element = this[idx];
      this.splice(idx, 1);
      if (!this.isNew) await element.delete();
    }
  }

  fetchAll(): Promise<void> {
    return Promise.resolve(undefined);
  }

  findOrCreate(id: number, values: Partial<TO>): TO {
    const idx = this.findIndex((o) => o.id === id);
    if (idx <= 0) return this.create(values);
    return this[idx];
  }

  firstOrCreate(attributes: Partial<TO>, values: Partial<TO>): TO {
    return undefined;
  }

  async saveAll(): Promise<void> {
    await Promise.all(this.map((o) => o.save())).then(() => undefined);
  }

  updateOrCreate(attributes: Partial<TO>, values: Partial<TO>): TO {
    return undefined;
  }
}
