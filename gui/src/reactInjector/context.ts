import { DependencyContainer } from 'tsyringe';
import React from 'react';

const Context = React.createContext<DependencyContainer>(
  (undefined as unknown) as DependencyContainer
);
Context.displayName = 'InversifyContainerContext';

export default Context;
