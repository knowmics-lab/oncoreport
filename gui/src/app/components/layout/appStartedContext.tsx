/* eslint-disable @typescript-eslint/ban-types */
import React, { useState } from 'react';
import { useService } from '../../../reactInjector';
import { Settings } from '../../../api';

type ContextType = {
  started: boolean;
  setStarted: (value: boolean) => void;
};

export const StartedContext = React.createContext<ContextType>({
  started: false,
  setStarted: () => {},
});
StartedContext.displayName = 'AppStartedContext';

export default function AppStartedContext({
  children,
}: React.PropsWithChildren<{}>) {
  const settings = useService(Settings);

  const [started, setStarted] = useState(!settings.isLocal());
  return (
    <StartedContext.Provider
      value={{
        started,
        setStarted,
      }}
    >
      {children}
    </StartedContext.Provider>
  );
}
