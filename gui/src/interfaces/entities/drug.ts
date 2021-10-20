import { Entity } from '../common';

export interface Drug extends Entity {
  drugbank_id: string;
  name: string;
}
