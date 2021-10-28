import { useCallback, useState } from 'react';
import { InjectionToken } from 'tsyringe';
import { Collection, Nullable } from '../../interfaces';
import { useService } from '../../reactInjector';
import useAsyncEffect from './useAsyncEffect';
import { Repository } from '../../apiConnector';
import {
  EntityObject,
  QueryBuilderInterface,
  ResultSetInterface,
} from '../../apiConnector/interfaces/entity';
import useAsync from './useAsync';
import { SimpleMapType } from '../../apiConnector/interfaces/common';

type QueryBuilderCallback<E extends EntityObject> = (
  builder: QueryBuilderInterface<E>
) => QueryBuilderInterface<E>;

export default function useRawRepositoryFetch<
  E extends EntityObject,
  C = ResultSetInterface<E>
>(
  repositoryToken: InjectionToken<Repository<E>>,
  queryBuilderCallback: QueryBuilderCallback<E>,
  processingCallback: (data: ResultSetInterface<E>) => C,
  parameters?: SimpleMapType
): [boolean, C | undefined] {
  const repository = useService(repositoryToken);
  const { loading, value } = useAsync<C>(async () => {

  }, [repository]);

  const [loading, setLoading] = useState(false);
  const [data, setData] = useState<Nullable<V>>(undefined);
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
