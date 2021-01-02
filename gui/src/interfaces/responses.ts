import { MetaResponseType } from './common';

export interface ApiResponseSingle<T> {
  data: T;
}

export interface ApiResponseCollection<T> {
  data: T[];
  meta: MetaResponseType;
}

export interface DeleteResponse {
  message: string;
  errors: boolean;
}
