import IdentifiableEntity from '../../interfaces/common/identifiableEntity';
import { Adapter } from '../../interfaces/adapter';

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

  public async delete() {
    if (!this.isDeleted && this.oId) {
      await this.adapter.delete((this as unknown) as T);
    }
    this.isDeleted = true;
  }

  public async save() {
    if (this.isDeleted) throw new Error('Attempting to save deleted entity');
    let newData;
    if (this.oId) {
      newData = await this.adapter.update((this as unknown) as T);
    } else {
      newData = await this.adapter.create((this as unknown) as T);
    }
    this.fill(newData);
  }

  public async setId(newId: number) {
    if (this.isDeleted) throw new Error('Attempting to modify deleted entity');
    if (this.oId !== newId) {
      this.oId = newId;
      await this.refresh();
    }
  }

  public async fill(d: Partial<T>) {
    if (this.isDeleted) throw new Error('Attempting to fill deleted entity');
    Object.assign(this, d);
    this.oId = d.id;
  }

  public async refresh() {
    if (this.isDeleted) throw new Error('Attempting to refresh deleted entity');
    if (this.id) {
      const data = await this.adapter.fetchOne(this);
      this.fill(data);
    }
  }
}
