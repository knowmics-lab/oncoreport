import { Moment } from 'moment';

export default interface EntityWithDates {
  created_at: Moment;
  created_at_diff: string;
  updated_at: Moment;
  updated_at_diff: string;
}
