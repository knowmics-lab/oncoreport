/* eslint-disable @typescript-eslint/no-explicit-any,import/no-cycle */
import { InjectionToken } from 'tsyringe';
import RelationsType from '../enums/relationsType';
import { MapValueType } from './common';
import Repository from '../repository';
import Entity from '../entity/entity';

export type HasOneRelation<E extends Entity> = {
  type: RelationsType.ONE;
  repositoryToken: InjectionToken<Repository<E>>;
  noRecursionSave?: boolean;
};

export type HasManyRelation<E extends Entity> = {
  type: RelationsType.MANY;
  repositoryToken: InjectionToken<Repository<E>>;
  noRecursionSave?: boolean;
  foreignKey: keyof E | { [localKey: string]: keyof E };
};

export type HasManyReadonlyRelation<E extends Entity> = {
  type: RelationsType.MANY_READONLY;
  repositoryToken: InjectionToken<Repository<E>>;
};

export type Relation<E extends Entity> =
  | HasOneRelation<E>
  | HasManyRelation<E>
  | HasManyReadonlyRelation<E>;

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
  relation?: T extends Entity ? Relation<T> : undefined;
  serialize?: SerializationConfig<T>;
};
