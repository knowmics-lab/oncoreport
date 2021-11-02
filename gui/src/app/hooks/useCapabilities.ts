/* eslint-disable @typescript-eslint/no-explicit-any */
import { useCallback, useState } from 'react';
import { Capabilities } from '../../api/utils';
import { Utils } from '../../api';
import { runAsync } from '../components/utils';
import useEffectOnce from './useEffectOnce';

export default function useCapabilities(): [
  boolean,
  Capabilities | undefined,
  () => void
] {
  const [capabilities, setCapabilities] = useState<Capabilities>();
  const [loading, setLoading] = useState(false);
  const refresh = useCallback(() => {
    runAsync(async () => {
      setLoading(true);
      setCapabilities(await Utils.refreshCapabilities());
      setLoading(false);
    });
  }, [setLoading, setCapabilities]);

  useEffectOnce(() => {
    if (Utils.capabilitiesLoaded()) {
      setCapabilities(Utils.capabilities);
    } else {
      runAsync(async () => {
        setLoading(true);
        setCapabilities(await Utils.refreshCapabilities());
        setLoading(false);
      });
    }
  });

  return [loading, capabilities, refresh];
}
