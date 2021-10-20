import { Entity } from '../common';

export interface Disease extends Entity {
  icd_code: string;
  name: string;
  tumor: boolean;
}
