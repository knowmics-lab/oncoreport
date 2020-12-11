import { singleton } from 'tsyringe';
import Repository from './repository';
import type { DiseaseObject } from '../../interfaces';
import { DiseaseEntity } from '../entities';
import { DiseaseAdapter } from '../adapters';

@singleton()
export default class Disease extends Repository<DiseaseObject, DiseaseEntity> {
  public constructor(adapter: DiseaseAdapter) {
    super(adapter, DiseaseEntity);
  }
}
