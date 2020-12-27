/* eslint-disable no-underscore-dangle */
import { container, InjectionToken } from 'tsyringe';
import { has, get, set, unset } from 'lodash';
import uniqid from 'uniqid';
import Entity, { EntityEvent } from '../entities/entity';
import type {
  Adapter,
  Collection,
  IdentifiableEntity,
  SimpleMapArray,
  SimpleMapType,
  SortingSpec,
} from '../../interfaces';
import { SortingDirection } from '../../interfaces';
import EntityError from '../../errors/EntityError';

type RefreshListener = (page?: number) => void;

export default abstract class Repository<
  T extends IdentifiableEntity,
  U extends Entity<T>
> {
  private _itemsPerPage = 15;

  private _sorting: SortingSpec = {
    created_at: SortingDirection.desc,
  };

  protected adapter: Adapter<T>;

  protected token: InjectionToken<U>;

  protected instanceCache: SimpleMapArray<U> = {};

  protected pagesCache: SimpleMapArray<Collection<U>> = {};

  protected refreshListeners: SimpleMapType<RefreshListener> = {};

  protected constructor(adapter: Adapter<T>, token: InjectionToken<U>) {
    this.adapter = adapter;
    this.token = token;
  }

  protected entityFactory(d?: T): U {
    const id = d?.id;
    if (id && has(this.instanceCache, id)) {
      return get(this.instanceCache, id);
    }
    // Create an instance and add default event handlers
    const instance = container
      .resolve(this.token)
      .listen(EntityEvent.CREATE, (o) => {
        const iId = o.id;
        if (!iId) throw new EntityError('Unknown error');
        this.instanceCache[iId] = instance;
      })
      .listen(EntityEvent.DELETE, (o) => {
        const iId = o.id;
        if (!iId) throw new EntityError('Unknown error');
        if (has(this.instanceCache, iId)) {
          unset(this.instanceCache, iId);
        }
      });
    if (d && id) {
      set(this.instanceCache, id, instance.syncInitialize(d));
    }
    return instance;
  }

  protected async entityFactoryAsync(id?: number): Promise<U> {
    if (id && has(this.instanceCache, id)) {
      return this.instanceCache[id];
    }
    const instance = await this.entityFactory().initialize(id);
    if (id) {
      this.instanceCache[id] = instance;
    }
    return instance;
  }

  public new(): U {
    return this.entityFactory().initializeNew();
  }

  public async create(data: Partial<T>): Promise<U> {
    return (await this.new()).fill(data).save();
  }

  public async fetch(id: number): Promise<U> {
    return this.entityFactoryAsync(id);
  }

  get itemsPerPage(): number {
    return this._itemsPerPage;
  }

  set itemsPerPage(value: number) {
    // Empty the cache if the number if items per page changes!
    if (value !== this._itemsPerPage) {
      this.pagesCache = {};
    }
    this._itemsPerPage = value;
  }

  get sorting(): SortingSpec {
    return this._sorting;
  }

  set sorting(value: SortingSpec) {
    // Empty the cache if the sorting specifications changes!
    if (value !== this._sorting) {
      this.pagesCache = {};
    }
    this._sorting = value;
  }

  public async refreshPage(page: number): Promise<Collection<U>> {
    if (has(this.pagesCache, page)) {
      unset(this.pagesCache, page);
    }
    const result = await this.fetchPage(page);
    this.notifyRefresh(page);
    return result;
  }

  public async refreshAllPages(): Promise<Collection<U>> {
    this.pagesCache = {};
    const result = this.fetchPage();
    this.notifyRefresh();
    return result;
  }

  public async fetchPage(page = 1): Promise<Collection<U>> {
    if (!has(this.pagesCache, page)) {
      const tmpCollection = await this.adapter.fetchPage(
        this._itemsPerPage,
        this._sorting,
        page
      );
      set(this.pagesCache, page, {
        data: tmpCollection.data.map((v) => this.entityFactory(v)),
        meta: tmpCollection.meta,
      });
    }
    return get(this.pagesCache, page);
  }

  public subscribeRefresh(listener: RefreshListener): string {
    const id = uniqid();
    set(this.refreshListeners, id, listener);
    return id;
  }

  public unsubscribeRefresh(id: string) {
    unset(this.refreshListeners, id);
  }

  private notifyRefresh(page?: number) {
    Object.values(this.refreshListeners).forEach((l) => l(page));
  }
}
