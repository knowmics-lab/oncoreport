import { InjectionToken } from 'tsyringe';
import { IdentifiableEntity } from '../../interfaces';
import Repository from '../../api/repositories/repository';
import Entity from '../../api/entities/entity';
import useRawRepositoryFetch from './useRawRepositoryFetch';

export default function useRepositoryFetch<
  T extends IdentifiableEntity,
  U extends Entity<T>,
  V = U
>(
  repositoryToken: InjectionToken<Repository<T, U>>,
  mapCallback: (obj: U) => V = (o) => o as unknown as V
): [boolean, V[]] {
  return useRawRepositoryFetch(
    repositoryToken,
    (tmp) => tmp.data.map(mapCallback),
    []
  );
}
