import { singleton } from 'tsyringe';
import { DiseaseEntity } from '../entities';
import { DiseaseAdapter } from '../adapters';
import { Repository } from '../../apiConnector';

@singleton()
export default class Disease extends Repository<DiseaseEntity> {
  public constructor(adapter: DiseaseAdapter) {
    super(adapter, DiseaseEntity);
  }
}
