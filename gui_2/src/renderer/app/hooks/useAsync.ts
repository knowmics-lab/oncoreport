/* eslint-disable @typescript-eslint/no-explicit-any */
import { DependencyList, useCallback, useEffect, useState } from 'react';
import { runAsync } from '../components/utils';
import { Notifications } from '../../../api';

export default function useAsync<T>(
  callback: (manager: Notifications) => Promise<T>,
  deps: DependencyList = [],
  notifyErrors = true,
): { loading: boolean; error: any; value: T | undefined } {
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<unknown>();
  const [value, setValue] = useState<T | undefined>(undefined);
  const callbackMemoized = useCallback(() => {
    setLoading(true);
    runAsync(
      async (manager) => {
        setValue(await callback(manager));
      },
      setError,
      notifyErrors,
      () => setLoading(false),
    );
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, deps);

  useEffect(() => {
    callbackMemoized();
  }, [callbackMemoized]);

  return { loading, error, value };
}
