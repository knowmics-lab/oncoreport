import { useContext, useMemo } from 'react';
import { DependencyContainer, InjectionToken } from 'tsyringe';
import Context from './context';

export const useContainer = (): DependencyContainer => useContext(Context);

export const useService = <T>(id: InjectionToken<T>): T => {
  const container = useContainer();
  return useMemo(() => container.resolve<T>(id), [container, id]);
};

export const useAllServices = <T>(id: InjectionToken<T>): T[] => {
  const container = useContainer();
  return useMemo(() => container.resolveAll<T>(id), [container, id]);
};
