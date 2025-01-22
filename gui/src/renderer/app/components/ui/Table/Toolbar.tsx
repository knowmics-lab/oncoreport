/* eslint-disable react/no-array-index-key */
import React from 'react';
import MaterialToolbar from '@mui/material/Toolbar';
import IconButton from '@mui/material/IconButton';
import Input from '@mui/material/Input';
import InputLabel from '@mui/material/InputLabel';
import InputAdornment from '@mui/material/InputAdornment';
import FormControl from '@mui/material/FormControl';
import SearchIcon from '@mui/icons-material/Search';
import { styled, Theme } from '@mui/material';
import { EntityObject } from '../../../../../apiConnector/interfaces/entity';
import ToolbarAction from './ToolbarAction';
import { Alignment } from './types';
import type { TableState, ToolbarActionType } from './types';

const rootStyle = (theme: Theme) => ({
  paddingRight: theme.spacing(1),
  flexFlow: 'row nowrap',
  justifyContent: 'space-between',
  alignItems: 'center',
});
const searchStyle = (theme: Theme) => ({
  marginLeft: theme.spacing(-3),
});

const LeftDiv = styled('div')(({ theme }) => ({
  flex: '1 1 auto',
  color: theme.palette.text.secondary,
  order: 1,
}));
const RightDiv = styled('div')(({ theme }) => ({
  flex: '1 1 auto',
  color: theme.palette.text.secondary,
  textAlign: 'right',
  order: 3,
}));
const CenterDiv = styled('div')(({ theme }) => ({
  flex: '1 0 auto',
  color: theme.palette.text.secondary,
  textAlign: 'center',
  order: 2,
}));

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
    <MaterialToolbar sx={rootStyle}>
      <LeftDiv>
        {globalSearch && (
          <FormControl sx={searchStyle}>
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
      </LeftDiv>
      <CenterDiv>{renderActions(Alignment.center)}</CenterDiv>
      <RightDiv>{renderActions(Alignment.right)}</RightDiv>
    </MaterialToolbar>
  );
}

Toolbar.defaultProps = {
  onSearch: undefined,
  setLoading: undefined,
};
