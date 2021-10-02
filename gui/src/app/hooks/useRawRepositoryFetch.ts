import { useCallback, useState } from 'react';
import { InjectionToken } from 'tsyringe';
import { Collection, IdentifiableEntity, Nullable } from '../../interfaces';
import Entity from '../../api/entities/entity';
import Repository from '../../api/repositories/repository';
import { useService } from '../../reactInjector';
import useAsyncEffect from './useAsyncEffect';

export default function useRawRepositoryFetch<
  T extends IdentifiableEntity,
  U extends Entity<T>,
  V = U[]
>(
  repositoryToken: InjectionToken<Repository<T, U>>,
  processingCallback: (data: Collection<U>) => V,
  emptyResult: V
): [boolean, V] {
  const [loading, setLoading] = useState(false);
  const [data, setData] = useState<Nullable<V>>(undefined);
  const repository = useService(repositoryToken);
  const memoizedCallback = useCallback(async () => {
    if (!data && !loading) {
      setLoading(true);
      const tmp = await repository.fetchPage();
      setData(processingCallback(tmp));
      setLoading(false);
    }
  }, [data, loading, repository, processingCallback]);

  useAsyncEffect(async () => {
    await memoizedCallback();
  }, [memoizedCallback]);

  return [loading, data ?? emptyResult];
}
