import IdentifiableEntity from '../common/identifiableEntity';
import TimedEntity from '../common/timedEntity';
import { Disease } from './disease';
import { Gender } from '../enums';

export interface Patient extends IdentifiableEntity, TimedEntity {
  code: string;
  first_name: string;
  last_name: string;
  age: number;
  gender: Gender;
  disease: Disease;
  owner: unknown;
}
