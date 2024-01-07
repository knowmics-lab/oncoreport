import { singleton } from 'tsyringe';
import { PatientEntity } from '../entities';
import { PatientAdapter } from '../adapters';
import { Repository } from '../../apiConnector';

@singleton()
export default class Patient extends Repository<PatientEntity> {
  public constructor(adapter: PatientAdapter) {
    super(adapter, PatientEntity);
  }
}
