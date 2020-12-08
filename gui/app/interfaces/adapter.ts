import { SortingSpec } from './common';
import { Collection } from './collection';
import IdentifiableEntity from './common/identifiableEntity';
import Connector from '../api/adapters/connector';

export interface Adapter<T> {
  readonly connector: Connector;

  create(patient: T): Promise<T>;

  update(patient: T): Promise<T>;

  delete(patient: T): Promise<void>;

  fetchOne(id: number | IdentifiableEntity): Promise<T>;

  fetchPage(
    per_page: number,
    sorting: SortingSpec,
    page: number
  ): Promise<Collection<T>>;
}
