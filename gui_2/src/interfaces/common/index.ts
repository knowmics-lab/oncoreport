import { Dispatch, SetStateAction } from 'react';
import { SortingDirection } from '../enums';

export type { default as Entity } from './entity';
export type { default as EntityArray } from './entityArray';

// @Todo: move from here

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
  extensions: string[];
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

export type SortingSpec = SimpleMapType<SortingDirection>;
export type FilteringSpec = Nullable<
  | string
  | {
      by: string | string[];
      value: string;
    }
>;

export interface ResponseType<T> {
  validationErrors?: RecursiveMapType<string>;
  data?: T;
}

export type UploadProgressFunction = (
  percentage: number,
  bytesUploaded: number,
  bytesTotal: number,
) => void;

export type UploadState = {
  isUploading: boolean;
  uploadFile: string;
  uploadedBytes: number;
  uploadedPercent: number;
  uploadTotal: number;
};

export type UploadCallbacks = {
  uploadStart: (uploadFile: string) => void;
  uploadEnd: () => void;
  makeOnProgress: () => UploadProgressFunction;
};

export type UploadHook = [
  UploadState,
  UploadCallbacks,
  Dispatch<SetStateAction<UploadState>>,
];
