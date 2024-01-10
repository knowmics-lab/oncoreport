import { darkMode as electronDarkMode } from 'electron-util';
import { Dispatch, SetStateAction, useEffect } from 'react';
import useMediaQuery from './useMediaQuery';
import { useLocalStorage } from './useStorage';

export default function useDarkMode(): [
  boolean,
  Dispatch<SetStateAction<boolean | undefined>>,
] {
  const [darkMode, setDarkMode] = useLocalStorage(
    'useDarkMode',
    electronDarkMode.isEnabled ? true : undefined,
  );
  const prefersDarkMode = useMediaQuery('(prefers-color-scheme: dark)');

  useEffect(() => {
    if (darkMode !== undefined || !prefersDarkMode) return;
    // Set the dark mode from the media query only if we are setting the value
    // for the first time and dark mode is enabled
    setDarkMode(prefersDarkMode);
  }, [darkMode, prefersDarkMode, setDarkMode]);

  return [darkMode ?? false, setDarkMode];
}
