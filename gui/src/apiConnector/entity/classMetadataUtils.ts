/* eslint-disable @typescript-eslint/no-explicit-any */
import { Map } from 'immutable';

type MetaMap<T = any> = Map<string | symbol, T>;

export function pushToMetadataMap(
  key: symbol,
  target: any,
  property: string | symbol,
  value: any,
): void {
  const old = (Reflect.getMetadata(key, target) || Map()) as MetaMap;
  Reflect.defineMetadata(key, old.set(property, value), target);
}

export function getMetadataMap<T>(key: symbol, target: any): MetaMap<T> {
  return (Reflect.getMetadata(key, target) || Map()) as MetaMap<T>;
}

export function pushToMetadataArray(
  key: symbol,
  target: any,
  value: any,
): void {
  const old = Reflect.getMetadata(key, target) || [];
  Reflect.defineMetadata(key, [...old, value], target);
}

export function getMetadataArray<T>(key: symbol, target: any): T[] {
  return (Reflect.getMetadata(key, target) || []) as T[];
}
