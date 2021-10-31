/* eslint-disable class-methods-use-this */
import { injectable } from 'tsyringe';
import dayjs, { Dayjs } from 'dayjs';
import Entity, { field } from '../../apiConnector/entity/entity';
import { RelationsType } from '../../apiConnector';
import { PatientDiseaseAdapter } from '../adapters';
import { DiseaseEntity, LocationEntity } from './index';
import { TumorTypes } from '../../interfaces/enums';
import { DiseaseRepository, LocationRepository } from '../repositories';
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

  @field<Nullable<LocationEntity>>({
    fillable: true,
    relation: {
      type: RelationsType.ONE,
      repositoryToken: LocationRepository,
      noRecursionSave: true,
    },
  })
  location?: LocationEntity;

  @field<Nullable<TumorTypes>>({
    fillable: true,
  })
  type: Nullable<TumorTypes> = undefined;

  @field<number>({
    fillable: true,
  })
  T: Nullable<number> = undefined;

  @field<number>({
    fillable: true,
  })
  N: Nullable<number> = undefined;

  @field<Nullable<number>>({
    fillable: true,
  })
  M: Nullable<number> = undefined;

  @field<Dayjs>({
    fillable: true,
    date: true,
  })
  start_date: Dayjs = dayjs();

  @field<Nullable<Dayjs>>({
    fillable: true,
    date: true,
  })
  end_date: Nullable<Dayjs> = undefined;

  public constructor(adapter: PatientDiseaseAdapter) {
    super(adapter);
  }
}
