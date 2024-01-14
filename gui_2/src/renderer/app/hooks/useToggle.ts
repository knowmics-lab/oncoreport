import { useCallback, useState } from 'react';

export default function useToggle(
  defaultValue: boolean,
): [boolean, (newValue?: boolean) => void] {
  const [value, setValue] = useState(defaultValue);

  const toggleValue = useCallback((newValue?: boolean) => {
    setValue((currentValue) => newValue ?? !currentValue);
  }, []);

  return [value, toggleValue];
}
