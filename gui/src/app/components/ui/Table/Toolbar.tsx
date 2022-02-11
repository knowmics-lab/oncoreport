/* eslint-disable react/no-array-index-key */
import React from 'react';
import MaterialToolbar from '@material-ui/core/Toolbar';
import { createStyles, makeStyles } from '@material-ui/core/styles';
import IconButton from '@material-ui/core/IconButton';
import Input from '@material-ui/core/Input';
import InputLabel from '@material-ui/core/InputLabel';
import InputAdornment from '@material-ui/core/InputAdornment';
import FormControl from '@material-ui/core/FormControl';
import SearchIcon from '@material-ui/icons/Search';
import { EntityObject } from '../../../../apiConnector/interfaces/entity';
import ToolbarAction from './ToolbarAction';
import { Alignment } from './types';
import type { TableState, ToolbarActionType } from './types';

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
    search: {
      marginLeft: theme.spacing(-3),
    },
  })
);

type Props<E extends EntityObject> = {
  actions: ToolbarActionType<E>[];
  state: TableState;
  data: E[] | undefined;
  globalSearch: boolean;
  onSearch?: (value: string) => void;
  setLoading?: (loading: boolean) => void;
};

export default function Toolbar<E extends EntityObject>({
  actions,
  state,
  data,
  globalSearch,
  onSearch,
  setLoading,
}: Props<E>) {
  const classes = useStyles();
  const searchRef = React.useRef<HTMLInputElement>(null);
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
          setLoading={setLoading}
        />
      ));

  const performSearch = () => {
    if (searchRef.current && onSearch) {
      onSearch(searchRef.current.value);
    }
  };

  const randomId = Math.floor((1 + Math.random()) * 0x10000)
    .toString(16)
    .substring(1);
  const searchId = `table-search-field-${randomId}`;
  return (
    <MaterialToolbar className={classes.root}>
      <div className={classes.left}>
        {globalSearch && (
          <FormControl className={classes.search}>
            <InputLabel htmlFor={searchId}>Search table</InputLabel>
            <Input
              id={searchId}
              type="text"
              inputRef={searchRef}
              onKeyPress={(e) => {
                if (e.key === 'Enter') {
                  e.preventDefault();
                  performSearch();
                }
              }}
              endAdornment={
                <InputAdornment position="end">
                  <IconButton
                    aria-label="search"
                    onClick={performSearch}
                    onMouseDown={(e) => e.preventDefault()}
                  >
                    <SearchIcon />
                  </IconButton>
                </InputAdornment>
              }
            />
          </FormControl>
        )}
        {renderActions(Alignment.left)}
      </div>
      <div className={classes.center}>{renderActions(Alignment.center)}</div>
      <div className={classes.right}>{renderActions(Alignment.right)}</div>
    </MaterialToolbar>
  );
}

Toolbar.defaultProps = {
  onSearch: undefined,
  setLoading: undefined,
};
