/* eslint-disable class-methods-use-this */
import QueryResponse from '../interfaces/queryResponse';
import { PartialObject } from '../interfaces/common';
import { PaginationMetadata } from '../interfaces/paginationMetadata';
import { ignorePromise } from '../utils';
import {
  EntityObject,
  EntityObserver,
  RepositoryObject,
  ResultSetObserver,
} from '../interfaces/entity';
import { Adapter } from '../interfaces/adapter';

type WeakObserver<E extends EntityObject> = WeakRef<
  ResultSetObserver<ResultSet<E>>
>;

export default class ResultSet<E extends EntityObject> extends Array<E> {
  protected metadata?: PaginationMetadata;

  protected observers = new Array<WeakObserver<E>>();

  protected entityObserver: EntityObserver<E> = {
    updated: () => this.refreshed(),
    deleted: () => ignorePromise(this.refresh()),
  };

  protected adapter: Adapter<E>;

  public constructor(
    queryResponse: QueryResponse<PartialObject<E>>,
    protected repository: RepositoryObject<E>
  ) {
    super();
    this.adapter = repository.adapter;
    this.init(queryResponse);
  }

  protected init(queryResponse: QueryResponse<PartialObject<E>>) {
    this.forEach((e) => e.removeObserver(this.entityObserver));
    if (this.length > 0) this.length = 0;
    this.metadata = queryResponse.meta;
    for (const entityData of queryResponse.data) {
      super.push(
        this.repository
          .createEntitySync(entityData, this.parameters)
          .observe(this.entityObserver)
      );
    }
  }

  get paginated() {
    return !!this.metadata && this.metadata.per_page > 0;
  }

  get currentPage() {
    return this.metadata?.current_page ?? 0;
  }

  get lastPage() {
    return this.metadata?.last_page ?? 0;
  }

  get perPage() {
    return this.metadata?.per_page ?? 0;
  }

  get from() {
    return this.metadata?.current_page ?? (this.length === 0 ? 0 : 1);
  }

  get to() {
    return this.metadata?.current_page ?? this.length;
  }

  get total() {
    return this.metadata?.current_page ?? this.length;
  }

  get query() {
    return this.metadata?.query;
  }

  get parameters() {
    return this.metadata?.parameters;
  }

  /**
   * Informs this object that another class wants to listen to the events
   * @param o
   */
  public observe(o: ResultSetObserver<this>): this {
    this.observers.push(new WeakRef<typeof o>(o));
    return this;
  }

  /**
   * Remove an observer from this object
   * @param o
   */
  public removeObserver(o: ResultSetObserver<this>): this {
    this.observers = this.observers.filter((o1) => o1.deref() !== o);
    return this;
  }

  public async refresh() {
    this.refreshing();
    this.init(await this.adapter.query(this.query, this.parameters));
    this.refreshed();
  }

  public async first() {
    if (this.paginated && this.currentPage > 1) {
      this.changingPage();
      this.init(
        await this.adapter.query(
          {
            ...this.query,
            page: 1,
          },
          this.parameters
        )
      );
      this.changedPage();
    }
  }

  public async previous() {
    if (this.paginated && this.currentPage > 1) {
      this.changingPage();
      this.init(
        await this.adapter.query(
          {
            ...this.query,
            page: this.currentPage - 1,
          },
          this.parameters
        )
      );
      this.changedPage();
    }
  }

  public async next() {
    if (this.paginated && this.currentPage < this.lastPage) {
      this.changingPage();
      this.init(
        await this.adapter.query(
          {
            ...this.query,
            page: this.currentPage + 1,
          },
          this.parameters
        )
      );
      this.changedPage();
    }
  }

  public async last() {
    if (this.paginated && this.currentPage < this.lastPage) {
      this.changingPage();
      this.init(
        await this.adapter.query(
          {
            ...this.query,
            page: this.lastPage,
          },
          this.parameters
        )
      );
      this.changedPage();
    }
  }

  public pop(): E | undefined {
    if (this.length === 0) return undefined;
    return this[this.length - 1];
  }

  public push(): number {
    throw new Error('This object is read only');
  }

  public concat(): E[] {
    throw new Error('This object is read only');
  }

  public reverse(): E[] {
    throw new Error('This object is read only');
  }

  public shift(): E | undefined {
    if (this.length === 0) return undefined;
    return this[0];
  }

  public slice(): E[] {
    throw new Error('This object is read only');
  }

  public sort(): this {
    throw new Error('This object is read only');
  }

  public splice(): E[] {
    throw new Error('This object is read only');
  }

  public unshift(): number {
    throw new Error('This object is read only');
  }

  public fill(): this {
    throw new Error('This object is read only');
  }

  public copyWithin(): this {
    throw new Error('This object is read only');
  }

  /**
   * Clone this object
   */
  public clone(): ResultSet<E> {
    const clone = Object.create(this) as ResultSet<E>;
    clone.length = 0;
    clone.internalPush(...this);
    clone.metadata = this.metadata;
    clone.observers = this.observers;
    clone.adapter = this.adapter;
    clone.repository = this.repository;
    return clone;
  }

  protected refreshing(): void {
    this.observers.forEach((ref) => {
      const o = ref.deref();
      if (o && o.refreshing) o.refreshing(this);
    });
  }

  protected refreshed(): void {
    this.observers.forEach((ref) => {
      const o = ref.deref();
      if (o && o.refreshed) o.refreshed(this);
    });
  }

  protected changingPage(): void {
    this.observers.forEach((ref) => {
      const o = ref.deref();
      if (o && o.changingPage) o.changingPage(this);
    });
  }

  protected changedPage(): void {
    this.observers.forEach((ref) => {
      const o = ref.deref();
      if (o && o.changedPage) o.changedPage(this);
    });
  }

  protected internalPush(...items: E[]): number {
    return super.push(...items);
  }
}
