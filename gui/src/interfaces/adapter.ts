import { FilteringSpec, SimpleMapType, SortingSpec } from './common';
import Collection from './collection';
import IdentifiableEntity from './common/identifiableEntity';
import Connector from '../api/adapters/connector';

export interface Adapter<T> {
  readonly connector: Connector;

  create(entity: T): Promise<T>;

  update(entity: T): Promise<T>;

  delete(entity: T): Promise<void>;

  fetchOne(
    id: number | IdentifiableEntity,
    parameters?: SimpleMapType<string>
  ): Promise<T>;

  fetch(
    sorting?: SortingSpec,
    filtering?: FilteringSpec,
    page?: number,
    per_page?: number,
    parameters?: SimpleMapType<string>
  ): Promise<Collection<T>>;
}
