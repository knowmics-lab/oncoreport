import { singleton } from 'tsyringe';
import { Adapter, HttpClient } from '../../apiConnector';
import { LocationEntity } from '../entities';

@singleton()
export default class Location extends Adapter<LocationEntity> {
  protected isReadOnly = true;

  public constructor(client: HttpClient) {
    super(client);
  }

  get endpoint(): string {
    return 'locations';
  }
}
