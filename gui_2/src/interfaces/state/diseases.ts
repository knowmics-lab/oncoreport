import { Disease } from '../entities/disease';
import { SimpleMapArray } from '../common';

export interface LoadedDiseases<E extends Disease> {
  fetching: boolean;
  readonly items: SimpleMapArray<E>;
}

export default interface DiseasesState<E extends Disease> {
  readonly diseasesList: {
    refresh: boolean;
    data: E[];
    fetching: boolean;
  };
  readonly diseases: LoadedDiseases<E>;
}
