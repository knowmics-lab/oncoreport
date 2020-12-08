import { injectable } from 'tsyringe';
import Repository from './repository';
import { Patient as PatientObject } from '../../interfaces/entities/patient';
import PatientEntity from '../entities/patient';
import PatientAdapter from '../adapters/patient';

@injectable()
export default class Patient extends Repository<PatientObject, PatientEntity> {
  public constructor(adapter: PatientAdapter) {
    super(adapter, PatientEntity);
  }
}
