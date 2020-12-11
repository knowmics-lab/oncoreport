import { singleton } from 'tsyringe';
import Repository from './repository';
import type { PatientObject } from '../../interfaces';
import { PatientEntity } from '../entities';
import { PatientAdapter } from '../adapters';

@singleton()
export default class Patient extends Repository<PatientObject, PatientEntity> {
  public constructor(adapter: PatientAdapter) {
    super(adapter, PatientEntity);
  }
}
