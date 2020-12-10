import { singleton } from 'tsyringe';
import Repository from './repository';
import { Patient as PatientObject } from '../../interfaces/entities/patient';
import { PatientEntity } from '../entities';
import { PatientAdapter } from '../adapters';

@singleton()
export default class Patient extends Repository<PatientObject, PatientEntity> {
  public constructor(adapter: PatientAdapter) {
    super(adapter, PatientEntity);
  }
}
