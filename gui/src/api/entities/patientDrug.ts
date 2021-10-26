/* eslint-disable class-methods-use-this */
import { injectable } from 'tsyringe';
import dayjs, { Dayjs } from 'dayjs';
import {
  Entity,
  field,
  HasManyReadonly,
  RelationsType,
} from '../../apiConnector';
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

@injectable()
export default class PatientDrug extends Entity {
  @field<number>({
    fillable: true,
  })
  patient_id = -1;

  @field<PatientDiseaseEntity>({
    fillable: true,
    relation: {
      type: RelationsType.ONE,
      repositoryToken: PatientDiseaseRepository,
      noRecursionSave: true,
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
  })
  suspension_reasons?: HasManyReadonly<SuspensionReasonEntity>;

  @field<string>({
    fillable: true,
  })
  comment = '';

  @field<Dayjs>({
    fillable: true,
    date: true,
  })
  start_date: Dayjs = dayjs();

  @field<Dayjs>({
    fillable: true,
    date: true,
  })
  end_date: Dayjs = dayjs();

  public constructor(adapter: PatientDrugAdapter) {
    super(adapter);
  }
}
