import { SimpleMapArray, StatePaginationType } from '../common';
import { Patient } from '../entities/patient';

export interface PatientsCollection<E extends Patient> {
  readonly refreshAll: boolean;
  readonly refreshPages: number[];
  readonly state: StatePaginationType;
  readonly pages: SimpleMapArray<E[]>;
}

export interface LoadedPatients<E extends Patient> {
  fetching: boolean;
  submitting: number[];
  deleting: number[];
  readonly items: SimpleMapArray<E>;
}

export default interface PatientsState<E extends Patient> {
  readonly patientsList: PatientsCollection<E>;
  readonly patients: LoadedPatients<E>;
}
