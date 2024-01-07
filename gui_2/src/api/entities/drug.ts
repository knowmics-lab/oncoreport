import { injectable } from 'tsyringe';
import Entity, { field } from '../../apiConnector/entity/entity';
import { DrugAdapter } from '../adapters';

@injectable()
export default class Drug extends Entity {
  @field({
    fillable: true,
    readonly: true,
  })
  public drugbank_id = '';

  @field({
    fillable: true,
    readonly: true,
  })
  public name = '';

  public constructor(adapter: DrugAdapter) {
    super(adapter);
  }
}
