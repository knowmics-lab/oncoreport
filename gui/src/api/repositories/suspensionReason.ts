import { singleton } from 'tsyringe';
import { SuspensionReasonEntity } from '../entities';
import { SuspensionReasonAdapter } from '../adapters';
import { Repository } from '../../apiConnector';

@singleton()
export default class SuspensionReason extends Repository<SuspensionReasonEntity> {
  public constructor(adapter: SuspensionReasonAdapter) {
    super(adapter, SuspensionReasonEntity);
  }
}
