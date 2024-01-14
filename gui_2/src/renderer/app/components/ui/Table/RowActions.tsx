import React from 'react';
import type { RowActionType } from './types';
import RowAction from './RowAction';
import { EntityObject } from '../../../../../apiConnector/interfaces/entity';

type Props<E extends EntityObject> = {
  actions: RowActionType<E>[];
  data: E;
  size: 'small' | 'medium';
  setLoading?: (isLoading: boolean) => void;
};

export default function RowActions<E extends EntityObject>({
  actions,
  data,
  size,
  setLoading,
}: Props<E>) {
  const k = (i: number) => `action-${data.id}-${i}`;
  return (
    <>
      {actions.map((a, i) => (
        <RowAction
          action={a}
          data={data}
          size={size}
          key={k(i)}
          setLoading={setLoading}
        />
      ))}
    </>
  );
}

RowActions.defaultProps = {
  setLoading: undefined,
};
