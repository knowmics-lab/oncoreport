import { Moment } from 'moment';
import IdentifiableEntity from '../common/identifiableEntity';
import EntityWithDates from '../common/entityWithDates';
import { Gender } from '../enums';
import { Nullable } from '../common';
import EntityArray from '../common/entityArray';
import { Disease } from './disease';
import { Drug } from './drug';
import { SuspensionReason } from './suspensionReason';

export interface PatientDisease extends IdentifiableEntity, EntityWithDates {
  patient_id: number;
  patient: Nullable<Patient>;
  disease: Disease;
  location: Location;
  type: Nullable<string>;
  T: Nullable<number>;
  N: Nullable<number>;
  M: Nullable<number>;
  start_date: Moment;
  end_date: Moment;
}

export interface PatientDrug extends IdentifiableEntity, EntityWithDates {
  patient_id: number;
  disease_id: Nullable<number>;
  patient: Nullable<Patient>;
  disease: Nullable<Disease>;
  drug: Drug;
  location: Location;
  suspension_reasons: Nullable<EntityArray<SuspensionReason>>;
  start_date: Moment;
  end_date: Moment;
  comment: string;
}

export interface Patient extends IdentifiableEntity, EntityWithDates {
  code: string;
  first_name: string;
  last_name: string;
  age: number;
  gender: Gender;
  email?: Nullable<string>;
  fiscal_number?: Nullable<string>;
  city?: Nullable<string>;
  telephone?: Nullable<string>;
  diseases: Nullable<EntityArray<PatientDisease>>;
  primary_disease: PatientDisease;
  drugs: Nullable<EntityArray<PatientDrug>>;
  owner: never;
  user: never;
}
