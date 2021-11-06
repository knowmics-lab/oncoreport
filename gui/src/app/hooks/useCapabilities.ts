/* eslint-disable @typescript-eslint/no-explicit-any */
import { useCallback, useEffect, useState } from 'react';
import { Capabilities } from '../../api/utils';
import { Utils } from '../../api';
import { runAsync } from '../components/utils';

export default function useCapabilities(
  wait?: boolean
): [boolean, Capabilities | undefined, () => void] {
  const [capabilities, setCapabilities] = useState<Capabilities>();
  const [loading, setLoading] = useState(false);
  const refresh = useCallback(() => {
    runAsync(async () => {
      setLoading(true);
      setCapabilities(await Utils.refreshCapabilities());
      setLoading(false);
    });
  }, [setLoading, setCapabilities]);

  useEffect(() => {
    if (!wait) {
      if (Utils.capabilitiesLoaded()) {
        setCapabilities(Utils.capabilities);
      } else {
        runAsync(async () => {
          setLoading(true);
          setCapabilities(await Utils.refreshCapabilities());
          setLoading(false);
        });
      }
    }
  }, [wait]);

  return [loading, capabilities, refresh];
}
