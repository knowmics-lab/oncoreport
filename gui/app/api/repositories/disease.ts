import { singleton } from 'tsyringe';
import Repository from './repository';
import { Disease as DiseaseObject } from '../../interfaces/entities/disease';
import { DiseaseEntity } from '../entities';
import { DiseaseAdapter } from '../adapters';

@singleton()
export default class Disease extends Repository<DiseaseObject, DiseaseEntity> {
  public constructor(adapter: DiseaseAdapter) {
    super(adapter, DiseaseEntity);
  }
}
