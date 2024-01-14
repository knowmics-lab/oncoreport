import React, { useState } from 'react';
import { Field, useField } from 'formik';
import {
  Autocomplete as FormikAutocompleteField,
  AutocompleteProps as FormikAutocompleteProps,
  AutocompleteRenderInputParams as FormikRenderInputParams,
} from 'formik-mui';
import { TextField } from '@mui/material';
import { InjectionToken } from 'tsyringe';
import { useDebouncedCallback } from 'use-debounce';
import { EntityObject } from '../../../../../apiConnector/interfaces/entity';
import { Repository } from '../../../../../apiConnector';
import { QueryBuilderCallback } from '../../../hooks/useRepositoryQuery';
import { SimpleMapType } from '../../../../../apiConnector/interfaces/common';
import useRepositorySearch from '../../../hooks/useRepositorySearch';
import { formControlStyle } from '../../utils';

export interface AutocompleteFieldProps<
  T extends EntityObject,
  Multiple extends boolean | undefined,
  DisableClearable extends boolean | undefined,
  FreeSolo extends boolean | undefined,
> extends Omit<
    FormikAutocompleteProps<T, Multiple, DisableClearable, FreeSolo>,
    | 'form'
    | 'meta'
    | 'field'
    | 'fullWidth'
    | 'onInputChange'
    | 'renderInput'
    | 'options'
    | 'loading'
  > {
  name: string;
  label: string;
  repositoryToken: InjectionToken<Repository<T>>;
  queryBuilderCallback?: QueryBuilderCallback<T>;
  parameters?: SimpleMapType;
}

function CustomFormikTextField({
  label,
  name,
  ...params
}: FormikRenderInputParams & { label: string; name: string }) {
  const [, meta] = useField(name);
  const { touched, error } = meta;
  return (
    <TextField
      {...params}
      sx={formControlStyle}
      error={touched && !!error}
      helperText={error}
      label={label}
    />
  );
}

export default function AutocompleteField<
  T extends EntityObject,
  Multiple extends boolean | undefined,
  DisableClearable extends boolean | undefined,
  FreeSolo extends boolean | undefined,
>({
  label,
  name,
  repositoryToken,
  queryBuilderCallback,
  parameters,
  ...otherProps
}: AutocompleteFieldProps<T, Multiple, DisableClearable, FreeSolo>) {
  const [inputValue, setInputValue] = useState('');
  const [, meta] = useField(name);
  const dSetInputValue = useDebouncedCallback(
    (value) => setInputValue(value),
    500,
    { maxWait: 2000 },
  );
  const [loading, options] = useRepositorySearch(
    repositoryToken,
    inputValue.trim().length > 0 ? inputValue.trim() : undefined,
    parameters,
    queryBuilderCallback,
  );

  return (
    <Field
      name={name}
      component={FormikAutocompleteField}
      fullWidth
      options={loading ? [] : [meta.value, ...(options ?? [])]}
      onInputChange={(_e: never, newInputValue: string) => {
        dSetInputValue(newInputValue);
      }}
      loading={loading}
      renderInput={(params: FormikRenderInputParams) => {
        return <CustomFormikTextField {...params} name={name} label={label} />;
      }}
      {...otherProps}
    />
  );
}

AutocompleteField.defaultProps = {
  queryBuilderCallback: undefined,
  parameters: undefined,
};
