import {
  IdentifiableEntity,
  TimedEntity as ITimedEntity,
} from '../../interfaces';
import Entity, { fillable, userReadonly } from './entity';

export default abstract class TimedEntity<
  T extends IdentifiableEntity & ITimedEntity
> extends Entity<T> implements ITimedEntity {
  @fillable()
  @userReadonly()
  public created_at = '';

  @fillable()
  @userReadonly()
  public created_at_diff = '';

  @fillable()
  @userReadonly()
  public updated_at = '';

  @fillable()
  @userReadonly()
  public updated_at_diff = '';
}
