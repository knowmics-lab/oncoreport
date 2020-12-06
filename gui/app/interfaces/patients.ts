import { MetaResponseType, Nullable, StatePaginationType } from './common';
import { DiseaseCollectionItem } from './diseases';

export enum Gender {
  m = 'm',
  f = 'f',
}

export interface PatientBase {
  id: number;
  code: string;
  first_name: string;
  last_name: string;
  age: number;
  gender: Gender;
  disease: DiseaseCollectionItem;
  created_at: string;
  created_at_diff: string;
  updated_at: string;
  updated_at_diff: string;
  owner: unknown;
}

export interface Patient extends PatientBase {
  links: {
    self: string;
    owner: Nullable<string>;
    jobs: string;
  };
}

export interface PatientCollectionItem extends PatientBase {
  self_link: string;
  owner_link: Nullable<string>;
  jobs_link: string;
}

export interface PatientsCollection {
  data: Patient[];
  meta: MetaResponseType;
}

export interface PatientsListType {
  readonly refreshAll: boolean;
  readonly refreshPages: number[];
  readonly state: StatePaginationType;
  readonly pages: { readonly [page: number]: PatientCollectionItem[] };
}

export interface LoadedPatients {
  fetching: boolean;
  submitting: number[];
  deleting: number[];
  readonly items: { readonly [id: number]: Patient };
}

export interface PatientsStateType {
  readonly patientsList: PatientsListType;
  readonly patients: LoadedPatients;
}
