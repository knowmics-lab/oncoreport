import { SortingSpec } from './common';
import Collection from './collection';
import IdentifiableEntity from './common/identifiableEntity';
import Connector from '../api/adapters/connector';

export interface Adapter<T> {
  readonly connector: Connector;

  create(entity: T): Promise<T>;

  update(entity: T): Promise<T>;

  delete(entity: T): Promise<void>;

  fetchOne(id: number | IdentifiableEntity): Promise<T>;

  fetchPage(
    per_page: number,
    sorting: SortingSpec,
    page: number
  ): Promise<Collection<T>>;
}
