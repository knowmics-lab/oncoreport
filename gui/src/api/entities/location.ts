import { injectable } from 'tsyringe';
import Entity, { field } from '../../apiConnector/entity/entity';
import { LocationAdapter } from '../adapters';

@injectable()
export default class Location extends Entity {
  @field({
    readonly: true,
  })
  public name = '';

  public constructor(adapter: LocationAdapter) {
    super(adapter);
  }
}
