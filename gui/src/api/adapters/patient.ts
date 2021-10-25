import { singleton } from 'tsyringe';
import { Adapter, HttpClient } from '../../apiConnector';
import { PatientEntity } from '../entities';

@singleton()
export default class Patient extends Adapter<PatientEntity> {
  public constructor(client: HttpClient) {
    super(client);
  }

  get endpoint(): string {
    return 'patients';
  }
}
