import IdentifiableEntity from '../common/identifiableEntity';
import EntityWithDates from '../common/entityWithDates';

export interface Location extends IdentifiableEntity, EntityWithDates {
  name: string;
}
