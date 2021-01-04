/* eslint-disable class-methods-use-this */
import { injectable } from 'tsyringe';
import { Gender, PatientObject } from '../../interfaces';
import PatientAdapter from '../adapters/patient';
import Entity from './timedEntity';
import { field } from './entity';
import Disease from './disease';

@injectable()
export default class Patient extends Entity<PatientObject>
  implements PatientObject {
  @field({
    fillable: true,
  })
  age = -1;

  @field({
    fillable: true,
  })
  code = '';

  @field({
    fillable: true,
    withEntity: Disease,
  })
  disease!: Disease;

  @field({
    fillable: true,
  })
  first_name = '';

  @field({
    fillable: true,
  })
  gender: Gender = Gender.m;

  @field({
    fillable: true,
  })
  last_name = '';

  @field({
    fillable: false,
    readonly: true,
  })
  owner: unknown = {};

  public constructor(adapter: PatientAdapter) {
    super(adapter);
  }

  public get fullName() {
    return `${this.first_name} ${this.last_name}`;
  }
}
