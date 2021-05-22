import IdentifiableEntity from '../common/identifiableEntity';
import TimedEntity from '../common/timedEntity';
import { Disease } from './disease';
import { Gender } from '../enums';
import { Arrayable, Nullable, SimpleMapArray } from '../common';

export interface Patient extends IdentifiableEntity, TimedEntity {
  code: string;
  first_name: string;
  last_name: string;
  age: number;
  gender: Gender;
  disease: Disease;
  owner: unknown;
  tumors: Array<{id: number, name: string, sede:any[], type?:string, stadio?:{T?:number, N?:number, M?:number}, drugs:{id:number, name:string, start_date?:string, end_date?:string}[]}>;
  diseases: any[];
  tumor?: number;
  type?: string;
  drugs?: {id: number, name:string}[];
}
