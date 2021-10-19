import moment from 'moment';
import {
  IdentifiableEntity,
  EntityWithDates as IEntityWithDates,
} from '../../interfaces';
import Entity, { field } from './entity';

export default abstract class TimedEntity<
    T extends IdentifiableEntity & IEntityWithDates
  >
  extends Entity<T>
  implements IEntityWithDates
{
  @field({
    fillable: false,
    readonly: true,
  })
  public created_at = moment();

  @field({
    fillable: false,
    readonly: true,
  })
  public created_at_diff = '';

  @field({
    fillable: false,
    readonly: true,
  })
  public updated_at = moment();

  @field({
    fillable: false,
    readonly: true,
  })
  public updated_at_diff = '';
}
