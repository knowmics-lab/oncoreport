import { Dayjs } from 'dayjs';
import { Entity, Nullable } from '../common';
import { Gender } from '../enums';
import EntityArray from '../common/entityArray';
import { Disease } from './disease';
import { Drug } from './drug';
import { SuspensionReason } from './suspensionReason';

export interface PatientDisease extends Entity {
  patient_id: number;
  patient: Nullable<Patient>;
  disease: Disease;
  location: Location;
  type: Nullable<string>;
  T: Nullable<number>;
  N: Nullable<number>;
  M: Nullable<number>;
  start_date: Dayjs;
  end_date: Dayjs;
}

export interface PatientDrug extends Entity {
  patient_id: number;
  disease_id: Nullable<number>;
  patient: Nullable<Patient>;
  disease: Nullable<Disease>;
  drug: Drug;
  location: Location;
  suspension_reasons: Nullable<EntityArray<SuspensionReason>>;
  start_date: Dayjs;
  end_date: Dayjs;
  comment: string;
}

export interface Patient extends Entity {
  code: string;
  first_name: string;
  last_name: string;
  age: number;
  gender: Gender;
  // email?: Nullable<string>;
  // fiscal_number?: Nullable<string>;
  // city?: Nullable<string>;
  // telephone?: Nullable<string>;
  diseases: Nullable<EntityArray<PatientDisease>>;
  primary_disease: PatientDisease;
  drugs: Nullable<EntityArray<PatientDrug>>;
  owner: never;
  user: never;
}
