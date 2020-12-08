export type SimpleMapArray<T> = { [id: number]: T };

export type SimpleMapType<T> = { [name: string]: T };

export type RecursiveMapType<T> = {
  [name: string]: T | RecursiveMapType<T>;
};

export type Nullable<T> = T | undefined | null;

export type Arrayable<T> = T | T[];

export type MapType = {
  [name: string]: Nullable<Arrayable<string | number | boolean | MapType>>;
};

export interface FileFilter {
  name: string;
  extension: string;
}

export type DialogProperty = 'openFile' | 'openDirectory' | 'multiSelections';

export interface DialogOptions {
  title?: string;
  buttonLabel?: string;
  filters?: FileFilter[];
  message?: string;
  properties?: DialogProperty[];
}

export interface ErrorResponse {
  errors: RecursiveMapType<string>;
}

export interface AxiosHeaders {
  headers: SimpleMapType<unknown>;
}

export type ModifiableStateType = {
  readonly saving: boolean;
};

export interface MetaResponseType {
  current_page: number;
  last_page: number;
  per_page: number;
  from: number;
  to: number;
  total: number;
  sorting?: SortingSpec;
}

export interface StatePaginationType {
  readonly current_page: Nullable<number>;
  readonly last_page: Nullable<number>;
  readonly per_page: number;
  readonly total: Nullable<number>;
  readonly sorting?: SortingSpec;
  readonly fetching: boolean;
}

export type LoadedCollectionMeta = {
  readonly fetching: boolean;
};

export type SortingDirection = 'asc' | 'desc';

export type SortingSpec = SimpleMapType<SortingDirection>;

export interface ResponseType<T> {
  validationErrors?: RecursiveMapType<string>;
  data?: T;
}

export type UploadProgressFunction = (x: number, y: number, z: number) => void;
