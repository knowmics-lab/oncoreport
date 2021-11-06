/* eslint-disable @typescript-eslint/ban-types */
import React, { useState } from 'react';

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
  const [started, setStarted] = useState(false);
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
