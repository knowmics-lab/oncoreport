/* eslint-disable consistent-return,@typescript-eslint/no-explicit-any,@typescript-eslint/ban-ts-comment */
import {
  useCallback,
  useState,
  useEffect,
  Dispatch,
  SetStateAction,
} from 'react';

type Maybe<T> = T | undefined;
type DefaultValue<T> = (() => Maybe<T>) | Maybe<T>;

export default function useStorage<T = any>(
  key: string,
  defaultValue: DefaultValue<T>,
  storageObject: Storage,
): [Maybe<T>, Dispatch<SetStateAction<Maybe<T>>>, () => void] {
  const [value, setValue] = useState<Maybe<T>>(() => {
    const jsonValue = storageObject.getItem(key);
    if (jsonValue) return JSON.parse(jsonValue);

    if (typeof defaultValue === 'function') {
      // @ts-ignore
      return defaultValue();
    }
    return defaultValue;
  });

  useEffect(() => {
    if (value === undefined) return storageObject.removeItem(key);
    storageObject.setItem(key, JSON.stringify(value));
  }, [key, value, storageObject]);

  const remove = useCallback(() => {
    setValue(undefined);
  }, []);

  return [value, setValue, remove];
}

export function useLocalStorage<T = any>(
  key: string,
  defaultValue: DefaultValue<T> = undefined,
) {
  return useStorage(key, defaultValue, window.localStorage);
}

export function useSessionStorage<T = any>(
  key: string,
  defaultValue: DefaultValue<T> = undefined,
) {
  return useStorage(key, defaultValue, window.sessionStorage);
}
