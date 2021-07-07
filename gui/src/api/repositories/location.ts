import { singleton } from 'tsyringe';
import Repository from './repository';
import type { ResourceObject } from '../../interfaces';
import { ResourceEntity } from '../entities';
import { LocationAdapter } from '../adapters';

@singleton()
export default class Location extends Repository<
  ResourceObject,
  ResourceEntity
> {
  public constructor(adapter: LocationAdapter) {
    super(adapter, ResourceEntity);
  }
}
