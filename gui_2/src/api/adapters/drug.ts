import { singleton } from 'tsyringe';
import { Adapter, HttpClient } from '../../apiConnector';
import { DrugEntity } from '../entities';

@singleton()
export default class Drug extends Adapter<DrugEntity> {
  protected isReadOnly = true;

  public constructor(client: HttpClient) {
    super(client);
  }

  get endpoint(): string {
    return 'drugs';
  }
}
