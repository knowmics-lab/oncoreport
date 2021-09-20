import { Nullable } from './common';
import { DiseaseCollectionItem } from './diseases';
import { Resource } from './resource';

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
  email: string;
  fiscalNumber: string;
  disease: DiseaseCollectionItem;
  disease_stage: any;
  disease_site_id: number;
  created_at: string;
  created_at_diff: string;
  updated_at: string;
  updated_at_diff: string;
  owner: unknown;
  drugs: Resource[];
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
