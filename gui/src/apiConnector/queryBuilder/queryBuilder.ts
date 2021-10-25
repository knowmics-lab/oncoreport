/* eslint-disable @typescript-eslint/no-explicit-any,no-param-reassign,import/no-cycle */
import Entity from '../entity/entity';
import Adapter from '../httpClient/adapter';
import { SimpleMapType } from '../interfaces/common';
import { QueryRequest } from '../interfaces/queryRequest';
import FilteringOperands from '../enums/filteringOperands';
import SortingDirection from '../enums/sortingDirection';
import ResultSet from './resultSet';
import Repository from '../repository';

export default class QueryBuilder<E extends Entity = Entity> {
  protected queryRequest: QueryRequest = {};

  protected adapter: Adapter<E>;

  public constructor(
    protected repository: Repository<E>,
    protected parameters?: SimpleMapType
  ) {
    this.adapter = repository.adapter;
  }

  /**
   * Apply global search to this query. Global search disables any other filter.
   * @param search The search string
   */
  public search(search: string): this {
    this.queryRequest = {
      ...this.queryRequest,
      filter: { search },
    };
    return this;
  }

  /**
   * Apply simple filtering to this query. Simple filtering disables global search or advanced filtering.
   * @param filter_by A field or an array of fields where the filtering is applied
   * @param filter_value A value that is used to filter
   */
  public filter(filter_by: keyof E | (keyof E)[], filter_value: string): this {
    this.queryRequest = {
      ...this.queryRequest,
      filter: {
        filter_by: Array.isArray(filter_by)
          ? filter_by.map((f) => f.toString())
          : filter_by.toString(),
        filter_value,
      },
    };
    return this;
  }

  /**
   * Apply advanced filtering to this query. Advanced filtering disables any other filter.
   * Advanced filters can be chained by calling the where method multiple times
   * @param by A field
   * @param value A value
   * @param op An operand (default equal)
   */
  public where(by: keyof E, value: any, op?: FilteringOperands): this {
    this.queryRequest = {
      ...this.queryRequest,
      filter: {
        filter: [
          ...(this.queryRequest.filter && 'filter' in this.queryRequest.filter
            ? this.queryRequest.filter.filter
            : []),
          {
            by: by.toString(),
            op,
            value,
          },
        ],
      },
    };
    return this;
  }

  /**
   * Disable pagination for this query
   */
  public doNotPaginate(): this {
    this.queryRequest = {
      ...this.queryRequest,
      paginate: false,
    };
    return this;
  }

  /**
   * Paginate this query.
   * @param perPage The number of records per page
   */
  public paginate(perPage = 15): QueryBuilder<E> {
    this.queryRequest = {
      ...this.queryRequest,
      paginate: true,
      perPage,
    };
    return this;
  }

  /**
   * Order the results by a field
   * @param attribute the name of a field
   * @param direction the sorting direction
   */
  public orderBy(
    attribute: keyof E,
    direction?: SortingDirection | string
  ): this {
    let realDirection = SortingDirection.asc;
    if (typeof direction === 'undefined' || direction === null) {
      realDirection = SortingDirection.asc;
    } else if (typeof direction === 'string') {
      if (direction === 'asc') {
        realDirection = SortingDirection.asc;
      } else if (direction === 'desc') {
        realDirection = SortingDirection.desc;
      }
    }

    this.queryRequest = {
      ...this.queryRequest,
      sort: {
        ...(this.queryRequest.sort ?? {}),
        [attribute.toString()]: realDirection,
      },
    };
    return this;
  }

  public async get(page = 1): Promise<ResultSet<E>> {
    const clone = this.clone();
    clone.queryRequest.page = page;
    const response = await this.adapter.query(
      clone.queryRequest,
      clone.parameters
    );
    return new ResultSet<E>(response, clone.repository);
  }

  public async first() {
    return (await this.paginate(1).get(1)).shift();
  }

  private clone(): QueryBuilder<E> {
    const clone = Object.create(this) as QueryBuilder<E>;
    clone.adapter = this.adapter;
    clone.parameters = this.parameters;
    clone.repository = this.repository;
    clone.queryRequest = {
      ...this.queryRequest,
    };
    return clone;
  }
}
