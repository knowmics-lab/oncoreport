import {
  IdentifiableEntity,
  TimedEntity as ITimedEntity,
} from '../../interfaces';
import Entity, { field } from './entity';

export default abstract class TimedEntity<
  T extends IdentifiableEntity & ITimedEntity
> extends Entity<T> implements ITimedEntity {
  @field({
    fillable: false,
    readonly: true,
  })
  public created_at = '';

  @field({
    fillable: false,
    readonly: true,
  })
  public created_at_diff = '';

  @field({
    fillable: false,
    readonly: true,
  })
  public updated_at = '';

  @field({
    fillable: false,
    readonly: true,
  })
  public updated_at_diff = '';
}
