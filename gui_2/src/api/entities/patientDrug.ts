/* eslint-disable class-methods-use-this */
import { injectable } from 'tsyringe';
import dayjs, { Dayjs } from 'dayjs';
import Entity, { field } from '../../apiConnector/entity/entity';
import { HasManyReadonly, RelationsType } from '../../apiConnector';
import { PatientDrugAdapter } from '../adapters';
import {
  DrugEntity,
  PatientDiseaseEntity,
  SuspensionReasonEntity,
} from './index';
import {
  DrugRepository,
  PatientDiseaseRepository,
  SuspensionReasonRepository,
} from '../repositories';
import type { Nullable } from '../../apiConnector/interfaces/common';

@injectable()
export default class PatientDrug extends Entity {
  @field({
    fillable: true,
    serialize: {
      identifier: true,
    },
  })
  patient_id = -1;

  @field<PatientDiseaseEntity>({
    fillable: true,
    relation: {
      type: RelationsType.ONE,
      repositoryToken: PatientDiseaseRepository,
      noRecursionSave: true,
    },
    serialize: {
      nullable: true,
    },
  })
  disease?: PatientDiseaseEntity;

  @field<DrugEntity>({
    fillable: true,
    relation: {
      type: RelationsType.ONE,
      repositoryToken: DrugRepository,
      noRecursionSave: true,
    },
  })
  drug?: DrugEntity;

  @field<SuspensionReasonEntity>({
    fillable: true,
    relation: {
      type: RelationsType.MANY_READONLY,
      repositoryToken: SuspensionReasonRepository,
    },
    serialize: {
      nullable: true,
    },
  })
  suspension_reasons?: HasManyReadonly<SuspensionReasonEntity>;

  @field({
    fillable: true,
    serialize: {
      nullable: true,
    },
  })
  comment: Nullable<string> = null;

  @field<Dayjs>({
    fillable: true,
    date: true,
    serialize: {
      date: true,
    },
  })
  start_date: Dayjs = dayjs();

  @field({
    fillable: true,
    date: true,
    serialize: {
      nullable: true,
      date: true,
    },
  })
  end_date: Nullable<Dayjs> = dayjs();

  public constructor(adapter: PatientDrugAdapter) {
    super(adapter);
  }
}
