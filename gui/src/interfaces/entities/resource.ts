import IdentifiableEntity from '../common/identifiableEntity';
import EntityWithDates from '../common/entityWithDates';

export interface Resource extends IdentifiableEntity, EntityWithDates {
  id: number;
  name?: string;
}
