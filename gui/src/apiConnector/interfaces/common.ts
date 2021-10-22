export type Nullable<T> = T | undefined | null;

export type Arrayable<T> = T | T[];

export type MapType = {
  [name: string]: Nullable<Arrayable<string | number | boolean | MapType>>;
};

export type SimpleMapType<T> = { [name: string]: T };

export type PartialObject<T> = {
  -readonly [name in keyof T]?: T[name];
};
