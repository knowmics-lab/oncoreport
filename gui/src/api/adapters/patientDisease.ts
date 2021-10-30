import { singleton } from 'tsyringe';
import { Adapter, HttpClient } from '../../apiConnector';
import { PatientDiseaseEntity } from '../entities';

@singleton()
export default class PatientDisease extends Adapter<PatientDiseaseEntity> {
  public constructor(client: HttpClient) {
    super(client);
  }

  get endpoint(): string {
    return 'patients/%(patient_id)d/diseases';
  }
}
