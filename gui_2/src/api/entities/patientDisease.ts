/* eslint-disable class-methods-use-this */
import { injectable } from 'tsyringe';
import dayjs, { Dayjs } from 'dayjs';
import Entity, { field } from '../../apiConnector/entity/entity';
import { RelationsType } from '../../apiConnector';
import { PatientDiseaseAdapter } from '../adapters';
import { DiseaseEntity } from './index';
import { TumorTypes } from '../../interfaces/enums';
import { DiseaseRepository } from '../repositories';
import type { Nullable } from '../../apiConnector/interfaces/common';

@injectable()
export default class PatientDisease extends Entity {
  @field<number>({
    fillable: true,
  })
  patient_id = -1;

  @field<DiseaseEntity>({
    fillable: true,
    relation: {
      type: RelationsType.ONE,
      repositoryToken: DiseaseRepository,
      noRecursionSave: true,
    },
  })
  disease?: DiseaseEntity;

  @field<Nullable<TumorTypes>>({
    fillable: true,
    serialize: {
      nullable: true,
    },
  })
  type: Nullable<TumorTypes> = null;

  @field<Nullable<number>>({
    fillable: true,
    serialize: {
      nullable: true,
      number: true,
    },
  })
  T: Nullable<number> = null;

  @field<Nullable<number>>({
    fillable: true,
    serialize: {
      nullable: true,
      number: true,
    },
  })
  N: Nullable<number> = null;

  @field<Nullable<number>>({
    fillable: true,
    serialize: {
      nullable: true,
      number: true,
    },
  })
  M: Nullable<number> = null;

  @field<Dayjs>({
    fillable: true,
    date: true,
    serialize: {
      date: true,
    },
  })
  start_date: Dayjs = dayjs();

  @field<Nullable<Dayjs>>({
    fillable: true,
    date: true,
    serialize: {
      nullable: true,
      date: true,
    },
  })
  end_date: Nullable<Dayjs> = undefined;

  public constructor(adapter: PatientDiseaseAdapter) {
    super(adapter);
    this.init();
  }
}
