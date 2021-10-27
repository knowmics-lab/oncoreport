/* eslint-disable class-methods-use-this */
import { injectable } from 'tsyringe';
import dayjs, { Dayjs } from 'dayjs';
import Entity, { field } from '../../apiConnector/entity/entity';
import { RelationsType } from '../../apiConnector';
import { PatientDiseaseAdapter } from '../adapters';
import { DiseaseEntity, LocationEntity } from './index';
import { TumorTypes } from '../../interfaces/enums';
import { DiseaseRepository, LocationRepository } from '../repositories';

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

  @field<LocationEntity>({
    fillable: true,
    relation: {
      type: RelationsType.ONE,
      repositoryToken: LocationRepository,
      noRecursionSave: true,
    },
  })
  location?: LocationEntity;

  @field<TumorTypes>({
    fillable: true,
  })
  age = TumorTypes.primary;

  @field<number>({
    fillable: true,
  })
  T = 0;

  @field<number>({
    fillable: true,
  })
  N = 0;

  @field<number>({
    fillable: true,
  })
  M = 0;

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

  public constructor(adapter: PatientDiseaseAdapter) {
    super(adapter);
  }
}
