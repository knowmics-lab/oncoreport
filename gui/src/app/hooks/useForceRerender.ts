import { useCallback, useState } from 'react';

export default function useForceRerender(): [number, () => void] {
  const [count, setCount] = useState(0);

  const forceRender = useCallback(() => {
    console.log("Chiamato 2");
    setCount((c) => c + 1);
  }, [setCount]);

  return [count, forceRender];
}
