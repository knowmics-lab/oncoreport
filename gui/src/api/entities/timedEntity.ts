import {
  IdentifiableEntity,
  EntityWithDates as ITimedEntity,
} from '../../interfaces';
import Entity, { field } from './entity';

export default abstract class TimedEntity<
    T extends IdentifiableEntity & EntityWithDates
  >
  extends Entity<T>
  implements EntityWithDates
{
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
