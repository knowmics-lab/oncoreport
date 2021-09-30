import IdentifiableEntity from '../common/identifiableEntity';
import TimedEntity from '../common/timedEntity';
import { Disease } from './disease';
import { Gender } from '../enums';
import { Nullable } from '../common';

export interface Patient extends IdentifiableEntity, TimedEntity {
  code: string;
  first_name: string;
  last_name: string;
  age: number;
  fiscalNumber: string;
  email: string;
  city?: Nullable<string>;
  telephone?: Nullable<string>;
  gender: Gender;
  disease: Disease;
  disease_stage: { T: number; M: number; N: number };
  disease_site_id: number;
  owner: unknown;
  tumors: Array<{
    id: number;
    name: string;
    sede: any[];
    type?: string;
    stadio?: { T?: number; N?: number; M?: number };
    drugs: {
      id: number;
      name: string;
      start_date?: string;
      end_date?: string;
    }[];
  }>;
  diseases: any[];
  tumor?: number;
  type?: string;
  drugs?: { id: number; name: string }[];
}
