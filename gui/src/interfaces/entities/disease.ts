import IdentifiableEntity from '../common/identifiableEntity';
import EntityWithDates from '../common/entityWithDates';

export interface Disease extends IdentifiableEntity, EntityWithDates {
  icd_code: string;
  name: string;
}
