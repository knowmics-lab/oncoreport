import IdentifiableEntity from '../common/identifiableEntity';
import EntityWithDates from '../common/entityWithDates';

export interface SuspensionReason extends IdentifiableEntity, EntityWithDates {
  name: string;
}
