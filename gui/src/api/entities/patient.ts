/* eslint-disable class-methods-use-this */
import { injectable } from 'tsyringe';
import { Gender } from '../../interfaces';
import { PatientAdapter } from '../adapters';
import Entity, { field } from '../../apiConnector/entity/entity';
import { HasMany, RelationsType } from '../../apiConnector';
import PatientDiseaseEntity from './patientDisease';
import PatientDrugEntity from './patientDrug';
import {
  PatientDiseaseRepository,
  PatientDrugRepository,
} from '../repositories';
import type { Nullable } from '../../apiConnector/interfaces/common';

@injectable()
export default class Patient extends Entity {
  @field<string>({
    fillable: true,
  })
  code = '';

  @field<string>({
    fillable: true,
  })
  first_name = '';

  @field<string>({
    fillable: true,
  })
  last_name = '';

  @field<number>({
    fillable: true,
  })
  age = -1;

  @field<Gender>({
    fillable: true,
  })
  gender: Gender = Gender.m;

  @field<string>({
    fillable: true,
  })
  email = '';

  @field<Nullable<string>>({
    fillable: true,
  })
  fiscal_number: Nullable<string> = undefined;

  @field<Nullable<string>>({
    fillable: true,
  })
  telephone: Nullable<string> = undefined;

  @field<Nullable<string>>({
    fillable: true,
  })
  city: Nullable<string> = undefined;

  @field<PatientDiseaseEntity>({
    fillable: true,
    relation: {
      type: RelationsType.MANY,
      repositoryToken: PatientDiseaseRepository,
      foreignKey: 'patient_id',
    },
    serialize: {
      serializable: false,
    },
  })
  diseases?: HasMany<PatientDiseaseEntity>;

  @field<PatientDiseaseEntity>({
    fillable: true,
    relation: {
      type: RelationsType.ONE,
      repositoryToken: PatientDiseaseRepository,
      noRecursionSave: true,
      fullyDumpInDataObject: true,
    },
    serialize: {
      serializable: true,
      dumpFullObject: true,
    },
  })
  primary_disease!: PatientDiseaseEntity;

  @field<PatientDrugEntity>({
    fillable: true,
    relation: {
      type: RelationsType.MANY,
      repositoryToken: PatientDrugRepository,
      foreignKey: 'patient_id',
    },
    serialize: {
      serializable: false,
    },
  })
  drugs?: HasMany<PatientDrugEntity>;

  public constructor(adapter: PatientAdapter) {
    super(adapter);
  }

  public get fullName() {
    return `${this.first_name} ${this.last_name}`;
  }
}
