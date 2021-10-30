import { useCallback, useEffect, useState } from 'react';
import { InjectionToken } from 'tsyringe';
import { useService } from '../../reactInjector';
import useAsyncEffect from './useAsyncEffect';
import { Repository } from '../../apiConnector';
import {
  EntityObject,
  QueryBuilderInterface,
  ResultSetInterface,
  ResultSetObserver,
} from '../../apiConnector/interfaces/entity';
import { SimpleMapType } from '../../apiConnector/interfaces/common';

export type QueryBuilderCallback<E extends EntityObject> = (
  builder: QueryBuilderInterface<E>
) => QueryBuilderInterface<E>;

export default function useRepositoryQuery<E extends EntityObject>(
  repositoryToken: InjectionToken<Repository<E>>,
  queryBuilderCallback?: QueryBuilderCallback<E>,
  parameters?: SimpleMapType
): [boolean, ResultSetInterface<E> | undefined, () => void] {
  const [loading, setLoading] = useState(false);
  const [data, setData] = useState<ResultSetInterface<E>>();
  const repository = useService(repositoryToken);
  const memoizedCallback = useCallback(async () => {
    if (!data && !loading) {
      setLoading(true);
      let query = repository.query(parameters);
      if (queryBuilderCallback) query = queryBuilderCallback(query);
      setData(await query.get());
      setLoading(false);
    }
  }, [data, loading, parameters, queryBuilderCallback, repository]);

  useAsyncEffect(async () => {
    await memoizedCallback();
  }, [memoizedCallback]);

  useEffect(() => {
    const observer: ResultSetObserver<ResultSetInterface<E>> = {
      refreshing() {
        setLoading(true);
      },
      refreshed(o: ResultSetInterface<E>) {
        setData(o.clone().removeObserver(this));
        setLoading(false);
      },
      changingPage() {
        setLoading(true);
      },
      changedPage(o: ResultSetInterface<E>) {
        setData(o.clone().removeObserver(this));
        setLoading(false);
      },
    };
    if (data) data.observe(observer);
    return () => {
      if (data) data.removeObserver(observer);
    };
  }, [data]);

  return [loading, loading ? undefined : data, () => setData(undefined)];
}
