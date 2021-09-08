import { singleton } from 'tsyringe';
import Repository from './repository';
import type { ResourceObject } from '../../interfaces';
import { ResourceEntity } from '../entities';
import { ReasonAdapter } from '../adapters';

@singleton()
export default class Reason extends Repository<ResourceObject, ResourceEntity> {
  public constructor(adapter: ReasonAdapter) {
    super(adapter, ResourceEntity);
  }
}
