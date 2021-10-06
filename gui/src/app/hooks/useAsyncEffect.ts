import { DependencyList, useCallback, useEffect } from 'react';
import { runAsync } from '../components/utils';
import { Notifications } from '../../api';

export default function useAsyncEffect(
  callback: (manager: Notifications) => Promise<void>,
  deps: DependencyList = []
) {
  const callbackMemoized = useCallback(() => {
    runAsync(callback);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, deps);

  useEffect(() => {
    callbackMemoized();
  }, [callbackMemoized]);
}
