import { PaginationMetadata } from './paginationMetadata';

export default interface QueryResponse<T> {
  data: T[];
  meta?: PaginationMetadata;
}
