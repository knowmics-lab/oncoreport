import { singleton } from 'tsyringe';
import { PatientDrugEntity } from '../entities';
import { PatientDrugAdapter } from '../adapters';
import { Repository } from '../../apiConnector';

@singleton()
export default class Patient extends Repository<PatientDrugEntity> {
  public constructor(adapter: PatientDrugAdapter) {
    super(adapter, PatientDrugEntity);
  }
}
