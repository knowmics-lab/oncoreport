import { TextField } from '@material-ui/core';
import { Autocomplete } from '@material-ui/lab';
import { Field, FieldProps, useField } from 'formik';
import React, { useCallback } from 'react';
import {
  AutocompleteProps as MuiAutocompleteProps,
  AutocompleteRenderInputParams as FormikRenderInputParams,
} from '@material-ui/lab/Autocomplete/Autocomplete';
import useStyles from './hooks';

interface Option<T> {
  label: string;
  value: T;
}

type MaybeOption<T> = Option<T> | Option<T>[] | null;

interface AutocompleteProps<T>
  extends FieldProps,
    Omit<
      MuiAutocompleteProps<Option<T>, true, false, false>,
      'name' | 'value' | 'defaultValue' | 'multiple' | 'renderInput'
    > {
  label: string;
  onChangeCallback?: (option: MaybeOption<T>) => void;
}

function CustomFormikTextField({
  label,
  name,
  ...params
}: FormikRenderInputParams & { label: string; name: string }) {
  const classes = useStyles();
  const [, meta] = useField(name);
  const { touched, error } = meta;
  return (
    <TextField
      {...params}
      className={classes.formControl}
      error={touched && !!error}
      helperText={error}
      label={label}
    />
  );
}

function CustomSelect<T>({
  label,
  field,
  form,
  options,
  onChangeCallback,
  ...otherProps
}: AutocompleteProps<T>) {
  const onChange = useCallback(
    (_e: unknown, option: MaybeOption<T>) => {
      let cleanedOption;
      if (option && Array.isArray(option)) {
        cleanedOption = option.map((item) => item.value);
      } else if (option && !Array.isArray(option)) {
        cleanedOption = [option.value];
      }
      form.setFieldValue(field.name, cleanedOption);
      if (onChangeCallback) {
        onChangeCallback(option);
      }
    },
    [field.name, form, onChangeCallback],
  );

  const getValue = useCallback(() => {
    const { value } = field;
    if (options && value) {
      const vArray = Array.isArray(value) ? value : [value];
      return options.filter((o) => vArray.includes(o.value));
    }
    return [];
  }, [field, options]);

  return (
    <Autocomplete
      options={options}
      getOptionLabel={(option) => option.label}
      autoComplete
      autoHighlight
      value={getValue()}
      onChange={onChange}
      multiple
      renderInput={(params) => (
        <CustomFormikTextField {...params} name={field.name} label={label} />
      )}
      {...otherProps}
    />
  );
}

CustomSelect.defaultProps = {
  onChangeCallback: undefined,
};

interface MultiSelectProps<T>
  extends Omit<
    AutocompleteProps<T>,
    | 'form'
    | 'meta'
    | 'field'
    | 'fullWidth'
    | 'onInputChange'
    | 'renderInput'
    | 'loading'
  > {
  name: string;
  label: string;
}

export default function MultiSelectField<T>({
  name,
  ...otherProps
}: MultiSelectProps<T>) {
  return <Field name={name} component={CustomSelect} {...otherProps} />;
}
