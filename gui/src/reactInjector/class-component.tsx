/* eslint-disable @typescript-eslint/no-explicit-any,react/jsx-props-no-spreading */
import React, { forwardRef, useMemo } from 'react';
import { InjectionToken } from 'tsyringe';
import { useAllServices, useContainer, useService } from './hooks';

type ReactComponent<P = any> =
  | React.ClassicComponentClass<P>
  | React.ComponentClass<P>
  | React.FunctionComponent<P>
  | React.ForwardRefExoticComponent<P>;

export type Options = {
  forwardRef?: boolean;
};

function getDisplayName(comp: any) {
  return (
    comp.displayName ||
    comp.name ||
    (comp.constructor &&
      (comp.constructor.displayName || comp.constructor.name)) ||
    'Component'
  );
}

function createDisplayName(Target: ReactComponent): string {
  return `InjectedComponent(${getDisplayName(Target)})`;
}

function useCreateHOC<C extends ReactComponent>(
  Target: C,
  propName: string,
  value: () => any,
  options?: Options
) {
  const useGetProps = (props: any) => {
    const extractedValue = value();
    return useMemo(
      () => ({
        ...props,
        [propName]: extractedValue,
      }),
      [props, extractedValue]
    );
  };

  if (options && options.forwardRef === true) {
    // eslint-disable-next-line react/display-name
    const forwarded = (forwardRef((props: any, ref: any) => {
      const targetProps = useGetProps(props);
      return <Target ref={ref} {...targetProps} />;
    }) as unknown) as C;
    forwarded.displayName = createDisplayName(Target);
    return forwarded;
  }

  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  function InjectedComponent(props: any) {
    const targetProps = useGetProps(props);
    return <Target {...targetProps} />;
  }

  InjectedComponent.displayName = createDisplayName(Target);

  return (InjectedComponent as unknown) as C;
}

export function injectContainer(propName: string, options?: Options) {
  return <C extends ReactComponent>(Target: C) => {
    return useCreateHOC(Target, propName, () => useContainer(), options);
  };
}

export function injectService<S>(
  propName: string,
  id: InjectionToken<S>,
  options?: Options
) {
  return <C extends ReactComponent>(Target: C) => {
    return useCreateHOC(Target, propName, () => useService<S>(id), options);
  };
}

export function injectAllServices<S>(
  propName: string,
  id: InjectionToken<S>,
  options?: Options
) {
  return <C extends ReactComponent>(Target: C) => {
    return useCreateHOC(Target, propName, () => useAllServices<S>(id), options);
  };
}
