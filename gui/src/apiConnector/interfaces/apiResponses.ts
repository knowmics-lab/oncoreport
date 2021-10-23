import { PaginationMetadata } from './paginationMetadata';

export interface Single<T> {
  data: T;
}

export interface Collection<T> {
  data: T[];
  meta: PaginationMetadata;
}
