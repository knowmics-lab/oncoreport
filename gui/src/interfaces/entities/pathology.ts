import { Resource } from '../resource';

export interface Pathology extends Resource {
  medicines: Resource[];
}
