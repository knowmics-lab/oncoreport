import { singleton } from 'tsyringe';
import { PatientDiseaseEntity } from '../entities';
import { PatientDiseaseAdapter } from '../adapters';
import { Repository } from '../../apiConnector';

@singleton()
export default class Patient extends Repository<PatientDiseaseEntity> {
  public constructor(adapter: PatientDiseaseAdapter) {
    super(adapter, PatientDiseaseEntity);
  }
}
