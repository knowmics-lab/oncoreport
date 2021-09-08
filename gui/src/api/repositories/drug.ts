import { singleton } from 'tsyringe';
import Repository from './repository';
import type { ResourceObject } from '../../interfaces';
import { ResourceEntity } from '../entities';
import { DrugAdapter } from '../adapters';

@singleton()
export default class Drug extends Repository<ResourceObject, ResourceEntity> {
  public constructor(adapter: DrugAdapter) {
    super(adapter, ResourceEntity);
  }
}
