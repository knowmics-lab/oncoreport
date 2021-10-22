import { QueryRequest } from './queryRequest';

export interface PaginationMetadata {
  current_page: number;
  last_page: number;
  per_page: number;
  from: number;
  to: number;
  total: number;
  query?: QueryRequest;
}
