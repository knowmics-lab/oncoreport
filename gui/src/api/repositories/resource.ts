import { singleton } from 'tsyringe';
import Repository from './repository';
import type { ResourceObject } from '../../interfaces';
import { ResourceEntity } from '../entities';
import { ResourceAdapter } from '../adapters';

@singleton()
export default class Resource extends Repository<ResourceObject, ResourceEntity> {
  public constructor(adapter: ResourceAdapter) {
    super(adapter, ResourceEntity);
  }
}
