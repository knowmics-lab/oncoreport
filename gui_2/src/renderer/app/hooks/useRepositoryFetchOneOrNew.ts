import { useCallback, useState } from 'react';
import { InjectionToken } from 'tsyringe';
import { useService } from '../../reactInjector';
import useAsyncEffect from './useAsyncEffect';
import { EntityObject } from '../../apiConnector/interfaces/entity';
import { Repository } from '../../apiConnector';
import { SimpleMapType } from '../../apiConnector/interfaces/common';

type OutputType<V> = [boolean, V | undefined, () => void];

export default function useRepositoryFetchOneOrNew<E extends EntityObject>(
  repositoryToken: InjectionToken<Repository<E>>,
  id?: number,
  parameters?: SimpleMapType,
): OutputType<E> {
  const [loading, setLoading] = useState(false);
  const [data, setData] = useState<E | undefined>(undefined);
  const repository = useService(repositoryToken);
  const memoizedCallback = useCallback(async () => {
    if (!data && !loading) {
      setLoading(true);
      setData(
        await (id && id > 0
          ? repository.fetch(id, parameters)
          : repository.new(undefined, parameters)),
      );
      setLoading(false);
    }
  }, [data, id, loading, parameters, repository]);

  const refreshCallback = useCallback(() => {
    setData(undefined);
  }, []);

  useAsyncEffect(async () => {
    await memoizedCallback();
  }, [memoizedCallback]);

  return [loading, loading ? undefined : data, refreshCallback];
}
