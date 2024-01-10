import { useEffect, useLayoutEffect, useRef } from 'react';
import { Nullable } from '../../apiConnector/interfaces/common';

export default function useInterval(
  callback: () => void | Promise<void>,
  delay: Nullable<number>,
) {
  const savedCallback = useRef(callback);

  // Remember the latest callback if it changes.
  useLayoutEffect(() => {
    savedCallback.current = callback;
  }, [callback]);

  // Set up the interval.
  useEffect(() => {
    // Don't schedule if no delay is specified.
    if (!delay) {
      return;
    }

    const id = setInterval(() => savedCallback.current(), delay);

    // eslint-disable-next-line consistent-return
    return () => clearInterval(id);
  }, [delay]);
}
