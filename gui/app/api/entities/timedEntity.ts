import IdentifiableEntity from '../../interfaces/common/identifiableEntity';
import ITimedEntity from '../../interfaces/common/timedEntity';
import Entity from './entity';

export default abstract class TimedEntity<
  T extends IdentifiableEntity & ITimedEntity
> extends Entity<T> implements ITimedEntity {
  public created_at = '';

  public created_at_diff = '';

  public updated_at = '';

  public updated_at_diff = '';
}
