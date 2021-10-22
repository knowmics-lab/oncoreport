import { PaginationMetadata } from './paginationMetadata';

export interface ApiResponseSingle<T> {
  data: T;
}

export interface ApiResponseCollection<T> {
  data: T[];
  meta: PaginationMetadata;
}
