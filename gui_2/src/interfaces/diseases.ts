export interface DiseaseBase {
  id: number;
  name: string;
  created_at: string;
  created_at_diff: string;
  updated_at: string;
  updated_at_diff: string;
}

export interface Disease extends DiseaseBase {
  links: {
    self: string;
  };
}

export interface DiseaseCollectionItem extends DiseaseBase {
  self_link: string;
}

export interface DiseasesCollection {
  data: DiseaseCollectionItem[];
}

export interface LoadedDiseases {
  fetching: boolean;
  submitting: number[];
  deleting: number[];
  readonly items: { readonly [id: number]: Disease };
}

export interface DiseasesStateType {
  readonly diseasesList: Disease[];
  readonly diseases: LoadedDiseases;
}
