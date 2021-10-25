/* eslint-disable import/prefer-default-export,@typescript-eslint/no-explicit-any,import/no-cycle */
import { get, set } from 'lodash';
import produce, { Draft } from 'immer';
import dayjs from 'dayjs';
import { FieldOptions } from '../interfaces/fieldOptions';
import { pushToMetadataArray, pushToMetadataMap } from './classMetadataUtils';
import HasMany from '../relations/hasMany';
import RelationsType from '../enums/relationsType';

export const FILLABLE = Symbol.for('fillable');
export const READONLY = Symbol.for('readonly');
export const FIELDS = Symbol.for('fields');
export const DATES = Symbol.for('dates');
export const RELATIONS = Symbol.for('relations');
export const SERIALIZE = Symbol.for('serialize');

export function field<T = any>(options: FieldOptions<T> = {}) {
  return (target: any, key: string | symbol) => {
    pushToMetadataArray(FIELDS, target, key);
    if (options.fillable) pushToMetadataArray(FILLABLE, target, key);
    if (options.readonly) pushToMetadataArray(READONLY, target, key);
    if (options.date) pushToMetadataArray(DATES, target, key);
    if (options.relation)
      pushToMetadataMap(RELATIONS, target, key, options.relation);
    if (options.serialize)
      pushToMetadataMap(SERIALIZE, target, key, options.serialize);

    return Object.defineProperty(target, key, {
      get() {
        let value = get(this.data, key);
        if (
          options.relation &&
          options.relation.type === RelationsType.MANY &&
          typeof value === 'undefined'
        ) {
          value = new HasMany(
            options.relation.repositoryToken,
            this,
            options.relation.foreignKey as any
          );
          set(this.data, key, value);
        }
        return value;
      },
      set(value: T) {
        if (!options.readonly && !options.relation) {
          const nextState = produce(this.data, (draft: Draft<any>) => {
            draft[key] = value;
            if (options.date && !dayjs.isDayjs(draft[key])) {
              draft[key] = dayjs(draft[key]);
            }
          });
          if (this.data !== nextState) this.dirty = true;
          this.data = nextState;
        }
      },
      enumerable: true,
      configurable: true,
    });
  };
}
