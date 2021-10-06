import { useCallback, useState } from 'react';
import { InjectionToken } from 'tsyringe';
import { IdentifiableEntity } from '../../interfaces';
import Entity from '../../api/entities/entity';
import Repository from '../../api/repositories/repository';
import { useService } from '../../reactInjector';
import useAsyncEffect from './useAsyncEffect';

type OutputType<V> = [boolean, V | undefined, () => void];

export default function useRepositoryFetchOne<
  T extends IdentifiableEntity,
  U extends Entity<T>,
  V = U
>(
  repositoryToken: InjectionToken<Repository<T, U>>,
  id: number,
  processingCallback?: (entity: U) => V
): OutputType<V> {
  const [loading, setLoading] = useState(false);
  const [data, setData] = useState<V | undefined>(undefined);
  const repository = useService(repositoryToken);
  const memoizedCallback = useCallback(async () => {
    if (!data && !loading) {
      setLoading(true);
      const fetchedData = await (await repository.fetch(id)).refresh();
      setData(
        (processingCallback
          ? processingCallback(fetchedData)
          : fetchedData) as unknown as V
      );
      setLoading(false);
    }
  }, [data, id, loading, processingCallback, repository]);
  const refreshCallback = useCallback(() => {
    setData(undefined);
  }, []);

  useAsyncEffect(async () => {
    await memoizedCallback();
  }, [memoizedCallback]);

  return [loading, data, refreshCallback];
}
