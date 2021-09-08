import IdentifiableEntity from '../common/identifiableEntity';
import TimedEntity from '../common/timedEntity';

export interface Resource extends IdentifiableEntity, TimedEntity {
  id: number;
  name?: string;
}
