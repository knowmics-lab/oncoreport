/* eslint-disable @typescript-eslint/no-explicit-any */
export type Nullable<T> = T | undefined | null;

export type Arrayable<T> = T | T[];

export type MapValueType = Nullable<
  Arrayable<string | number | boolean | MapType>
>;

export type MapType = {
  [name: string]: MapValueType;
};

export type SimpleMapType<T = any> = { [name: string]: T };

export type PartialObject<T> = {
  -readonly [name in keyof T]?: T[name];
};
