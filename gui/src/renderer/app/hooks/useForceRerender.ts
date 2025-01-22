import { useCallback, useState } from 'react';

export default function useForceRerender(): [number, () => void] {
  const [count, setCount] = useState(0);

  const forceRender = useCallback(() => {
    setCount((c) => c + 1);
  }, [setCount]);

  return [count, forceRender];
}
