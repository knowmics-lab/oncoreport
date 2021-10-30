/* eslint-disable react/no-array-index-key */
import React from 'react';
import MaterialToolbar from '@material-ui/core/Toolbar';
import { createStyles, makeStyles } from '@material-ui/core/styles';
import type { TableState, ToolbarActionType } from './types';
import { Alignment } from './types';
import ToolbarAction from './ToolbarAction';
import { EntityObject } from '../../../../apiConnector/interfaces/entity';

const useStyles = makeStyles((theme) =>
  createStyles({
    root: {
      paddingRight: theme.spacing(1),
      flexFlow: 'row nowrap',
      justifyContent: 'space-between',
      alignItems: 'center',
    },
    title: {
      flex: '0 0 auto',
      color: theme.palette.text.primary,
      order: 0,
    },
    left: {
      flex: '1 1 auto',
      color: theme.palette.text.secondary,
      order: 1,
    },
    right: {
      flex: '1 1 auto',
      color: theme.palette.text.secondary,
      textAlign: 'right',
      order: 3,
    },
    center: {
      flex: '1 0 auto',
      color: theme.palette.text.secondary,
      textAlign: 'center',
      order: 2,
    },
    actions: {
      color: theme.palette.text.secondary,
    },
  })
);

type Props<E extends EntityObject> = {
  actions: ToolbarActionType<E>[];
  state: TableState;
  data: E[] | undefined;
};

export default function Toolbar<E extends EntityObject>({
  actions,
  state,
  data,
}: Props<E>) {
  const classes = useStyles();
  if (!actions || actions.length === 0) return null;
  const renderActions = (d: Alignment) =>
    actions
      .filter((a) => a.align === d)
      .map((a, i) => (
        <ToolbarAction
          action={a}
          state={state}
          data={data}
          key={`toolbar-${d}-${i}`}
        />
      ));
  return (
    <MaterialToolbar className={classes.root}>
      <div className={classes.left}>{renderActions(Alignment.left)}</div>
      <div className={classes.center}>{renderActions(Alignment.center)}</div>
      <div className={classes.right}>{renderActions(Alignment.right)}</div>
    </MaterialToolbar>
  );
}
