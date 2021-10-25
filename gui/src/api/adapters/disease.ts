import { singleton } from 'tsyringe';
import { Adapter, HttpClient } from '../../apiConnector';
import { DiseaseEntity } from '../entities';

@singleton()
export default class Disease extends Adapter<DiseaseEntity> {
  protected isReadOnly = true;

  public constructor(client: HttpClient) {
    super(client);
  }

  get endpoint(): string {
    return 'diseases';
  }
}
