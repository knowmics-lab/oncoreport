import { MetaResponseType } from './common';

export default interface Collection<T> {
  data: T[];
  meta: MetaResponseType;
}
