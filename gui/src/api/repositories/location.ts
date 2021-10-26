import { singleton } from 'tsyringe';
import { LocationEntity } from '../entities';
import { LocationAdapter } from '../adapters';
import { Repository } from '../../apiConnector';

@singleton()
export default class Location extends Repository<LocationEntity> {
  public constructor(adapter: LocationAdapter) {
    super(adapter, LocationEntity);
  }
}
