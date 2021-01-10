import React from 'react';
import type { RowActionType } from './types';
import RowAction from './RowAction';
import { IdentifiableEntity } from '../../../../interfaces';
import Entity from '../../../../api/entities/entity';

type Props<D extends IdentifiableEntity, E extends Entity<D>> = {
  actions: RowActionType<D, E>[];
  data: E;
  size: 'small' | 'medium';
};

export default function RowActions<
  D extends IdentifiableEntity,
  E extends Entity<D>
>({ actions, data, size }: Props<D, E>) {
  const k = (i: number) => `action-${data.id}-${i}`;
  return (
    <>
      {actions.map((a, i) => (
        <RowAction action={a} data={data} size={size} key={k(i)} />
      ))}
    </>
  );
}
