/* eslint-disable class-methods-use-this */
import { injectable } from 'tsyringe';
import { Gender } from '../../interfaces';
import { PatientAdapter } from '../adapters';
import {
  Entity,
  field,
  HasMany,
  Nullable,
  RelationsType,
} from '../../apiConnector';
import PatientDiseaseEntity from './patientDisease';
import PatientDrugEntity from './patientDrug';
import {
  PatientDiseaseRepository,
  PatientDrugRepository,
} from '../repositories';

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

  @field<string>({
    fillable: true,
  })
  fiscalNumber = '';

  @field<Nullable<string>>({
    fillable: true,
  })
  telephone: Nullable<string> = null;

  @field<Nullable<string>>({
    fillable: true,
  })
  city: Nullable<string> = null;

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
  diseases?: HasMany<PatientDiseaseEntity, Patient>;

  @field<PatientDiseaseEntity>({
    fillable: true,
    relation: {
      type: RelationsType.ONE,
      repositoryToken: PatientDiseaseRepository,
      noRecursionSave: true,
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
  drugs?: HasMany<PatientDrugEntity, Patient>;

  public constructor(adapter: PatientAdapter) {
    super(adapter);
  }

  public get fullName() {
    return `${this.first_name} ${this.last_name}`;
  }
}
