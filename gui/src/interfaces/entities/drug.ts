import { Resource } from '../resource';

export interface Drug extends Resource {
  start_date?: string;
  end_date?: string;
  reasons?: Resource[];
  comment?: string;
}
