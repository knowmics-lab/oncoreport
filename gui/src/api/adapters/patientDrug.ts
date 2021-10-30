import { singleton } from 'tsyringe';
import { Adapter, HttpClient } from '../../apiConnector';
import { PatientDrugEntity } from '../entities';

@singleton()
export default class PatientDrug extends Adapter<PatientDrugEntity> {
  public constructor(client: HttpClient) {
    super(client);
  }

  get endpoint(): string {
    return 'patients/%(patient_id)d/drugs';
  }
}
