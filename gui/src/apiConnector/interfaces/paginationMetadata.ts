import { QueryRequest } from './queryRequest';
import { SimpleMapType } from './common';

export interface PaginationMetadata {
  current_page: number;
  last_page: number;
  per_page: number;
  from: number;
  to: number;
  total: number;
  query?: QueryRequest;
  parameters?: SimpleMapType;
}
