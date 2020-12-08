import { injectable } from 'tsyringe';
import Repository from './repository';
import { Disease as DiseaseObject } from '../../interfaces/entities/disease';
import DiseaseEntity from '../entities/disease';
import DiseaseAdapter from '../adapters/disease';

@injectable()
export default class Disease extends Repository<DiseaseObject, DiseaseEntity> {
  public constructor(adapter: DiseaseAdapter) {
    super(adapter, DiseaseEntity);
  }
}
