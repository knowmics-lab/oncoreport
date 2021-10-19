import IdentifiableEntity from '../common/identifiableEntity';
import EntityWithDates from '../common/entityWithDates';

export interface Drug extends IdentifiableEntity, EntityWithDates {
  drugbank_id: string;
  name: string;
}
