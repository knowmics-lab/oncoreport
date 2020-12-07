import IdentifiableEntity from '../common/identifiableEntity';
import TimedEntity from '../common/timedEntity';

export interface Disease extends IdentifiableEntity, TimedEntity {
  name: string;
}
