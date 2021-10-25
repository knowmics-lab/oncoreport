import { singleton } from 'tsyringe';
import { Adapter, HttpClient } from '../../apiConnector';
import { SuspensionReasonEntity } from '../entities';

@singleton()
export default class SuspensionReason extends Adapter<SuspensionReasonEntity> {
  protected isReadOnly = true;

  public constructor(client: HttpClient) {
    super(client);
  }

  get endpoint(): string {
    return 'suspension_reasons';
  }
}
