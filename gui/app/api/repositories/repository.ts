import { container, InjectionToken } from 'tsyringe';
import Entity from '../entities/entity';
import { Adapter } from '../../interfaces/adapter';
import { SortingSpec } from '../../interfaces/common';
import { Collection } from '../../interfaces/collection';

export default abstract class Repository<T, U extends Entity<T>> {
  protected adapter: Adapter<T>;

  protected token: InjectionToken<U>;

  protected constructor(adapter: Adapter<T>, token: InjectionToken<U>) {
    this.adapter = adapter;
    this.token = token;
  }

  protected makeEntity(): U {
    return container.resolve(this.token);
  }

  public async create(data: Partial<T>): Promise<U> {
    return this.makeEntity().fill(data).save();
  }

  public async fetch(id: number): Promise<U> {
    return this.makeEntity().setId(id);
  }

  public async fetchPage(
    per_page = 15,
    sorting: SortingSpec = { created_at: 'desc' },
    page = 1
  ): Promise<Collection<U>> {
    const tmpCollection = await this.adapter.fetchPage(per_page, sorting, page);
    return {
      data: tmpCollection.data.map((v) =>
        this.makeEntity().fillFromCollection(v)
      ),
      meta: tmpCollection.meta,
    };
  }
}
