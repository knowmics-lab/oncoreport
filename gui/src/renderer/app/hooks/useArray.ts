import { useState } from 'react';

export default function useArray<T>(defaultValue: T[] = []) {
  const [array, setArray] = useState(defaultValue);

  function shift(element: T) {
    setArray((a) => [element, ...a]);
  }

  function push(element: T) {
    setArray((a) => [...a, element]);
  }

  function filter(callback: (element: T) => boolean) {
    setArray((a) => a.filter(callback));
  }

  function update(index: number, newElement: T) {
    setArray((a) => [
      ...a.slice(0, index),
      newElement,
      ...a.slice(index + 1, a.length),
    ]);
  }

  function remove(element: T) {
    filter((e) => e !== element);
  }

  function removeAt(index: number) {
    setArray((a) => [...a.slice(0, index), ...a.slice(index + 1, a.length)]);
  }

  function clear() {
    setArray([]);
  }

  return {
    array,
    set: setArray,
    shift,
    push,
    filter,
    update,
    remove,
    removeAt,
    clear,
  };
}
