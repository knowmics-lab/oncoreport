import { singleton } from 'tsyringe';
import Repository from './repository';
import type { ResourceObject } from '../../interfaces';
import { ResourceEntity } from '../entities';
import { MedicineAdapter } from '../adapters';

@singleton()
export default class Medicine extends Repository<
  ResourceObject,
  ResourceEntity
> {
  public constructor(adapter: MedicineAdapter) {
    super(adapter, ResourceEntity);
  }
}
