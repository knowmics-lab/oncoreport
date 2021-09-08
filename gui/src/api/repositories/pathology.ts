import { singleton } from 'tsyringe';
import Repository from './repository';
import type { ResourceObject } from '../../interfaces';
import { ResourceEntity } from '../entities';
import { PathologyAdapter } from '../adapters';

@singleton()
export default class Pathology extends Repository<
  ResourceObject,
  ResourceEntity
> {
  public constructor(adapter: PathologyAdapter) {
    super(adapter, ResourceEntity);
  }
}
