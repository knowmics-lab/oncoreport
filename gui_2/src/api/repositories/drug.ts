import { singleton } from 'tsyringe';
import { DrugEntity } from '../entities';
import { DrugAdapter } from '../adapters';
import { Repository } from '../../apiConnector';

@singleton()
export default class Drug extends Repository<DrugEntity> {
  public constructor(adapter: DrugAdapter) {
    super(adapter, DrugEntity);
  }
}
