/* eslint-disable class-methods-use-this */
import { injectable } from 'tsyringe';
import { Gender, PatientObject } from '../../interfaces';
import PatientAdapter from '../adapters/patient';
import Entity from './timedEntity';
import { fillable, fillableWithEntity, userReadonly } from './entity';
import Disease from './disease';

@injectable()
export default class Patient extends Entity<PatientObject>
  implements PatientObject {
  @fillable()
  age = -1;

  @fillable()
  code = '';

  @fillable()
  @fillableWithEntity(Disease)
  disease!: Disease;

  @fillable()
  first_name = '';

  @fillable()
  gender: Gender = Gender.m;

  @fillable()
  last_name = '';

  @fillable()
  @userReadonly()
  owner: unknown = {};

  public constructor(adapter: PatientAdapter) {
    super(adapter);
  }
}
