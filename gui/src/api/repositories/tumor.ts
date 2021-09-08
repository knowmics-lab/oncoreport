import { singleton } from 'tsyringe';
import Repository from './repository';
import type { ResourceObject } from '../../interfaces';
import { ResourceEntity } from '../entities';
import { TumorAdapter } from '../adapters';

@singleton()
export default class Tumor extends Repository<ResourceObject, ResourceEntity> {
  public constructor(adapter: TumorAdapter) {
    super(adapter, ResourceEntity);
  }
}
