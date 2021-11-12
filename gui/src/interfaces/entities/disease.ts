import { Entity } from '../common';

export interface Disease extends Entity {
  doid: string;
  name: string;
  tumor: boolean;
}
