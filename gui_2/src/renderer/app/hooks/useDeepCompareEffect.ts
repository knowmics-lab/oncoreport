/* eslint-disable react-hooks/exhaustive-deps */
import { DependencyList, EffectCallback, useEffect, useRef } from 'react';
import isEqual from 'lodash/fp/isEqual';

export default function useDeepCompareEffect(
  callback: EffectCallback,
  dependencies: DependencyList,
) {
  const currentDependenciesRef = useRef<DependencyList>();

  if (!isEqual(currentDependenciesRef.current, dependencies)) {
    currentDependenciesRef.current = dependencies;
  }

  useEffect(callback, [currentDependenciesRef.current]);
}
