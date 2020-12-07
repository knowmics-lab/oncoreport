import { MetaResponseType } from './common';

export interface Collection<T> {
  data: T[];
  meta: MetaResponseType;
}
