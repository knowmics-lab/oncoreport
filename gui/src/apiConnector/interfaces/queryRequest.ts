/* eslint-disable @typescript-eslint/no-explicit-any */
import FilteringOperands from '../enums/filteringOperands';
import { SimpleMapType } from './common';
import SortingDirection from '../enums/sortingDirection';

export interface GlobalSearchFiltering {
  search: string;
}

export interface SimpleFiltering {
  filter_by: string | string[];
  filter_value: string;
}

export interface FilterSpec {
  by: string;
  op?: FilteringOperands;
  value: any;
}

export interface AdvancedFiltering {
  filter: FilterSpec[];
}

export interface QueryRequest {
  filter?: GlobalSearchFiltering | SimpleFiltering | AdvancedFiltering;
  sort?: SimpleMapType<SortingDirection>;
  paginate?: boolean;
  page?: number;
  perPage?: number;
}
