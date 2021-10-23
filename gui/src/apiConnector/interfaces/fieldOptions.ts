/* eslint-disable @typescript-eslint/no-explicit-any */
import { InjectionToken } from 'tsyringe';
import RelationsType from '../enums/relationsType';
import { MapValueType } from './common';

export type HasOneRelation<T> = {
  type: RelationsType.ONE;
  entityToken: InjectionToken<T>;
  noRecursionSave?: boolean;
};

export type HasManyRelation<T> = {
  type: RelationsType.MANY;
  entityToken: InjectionToken<T>;
  noRecursionSave?: boolean;
  foreignKey: keyof T | { [localKey: string]: keyof T };
};

export type Relation<T> = HasOneRelation<T> | HasManyRelation<T>;

export type SerializationConfig<T> = {
  serializable?: boolean;
  serialize?: (value: T, config: SerializationConfig<T>) => MapValueType;
  serializedKey?: string;
  dumpFullObject?: boolean;
};

export type FieldOptions<T = any> = {
  fillable?: boolean;
  readonly?: boolean;
  date?: boolean;
  relation?: Relation<T>;
  serialize?: SerializationConfig<T>;
};
