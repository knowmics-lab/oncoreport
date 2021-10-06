import { TextField } from '@material-ui/core';
import { Autocomplete } from '@material-ui/lab';
import { FieldProps } from 'formik';
import React from 'react';

interface Option {
  label: string;
  value: string;
}

interface FormikSelectProps extends FieldProps {
  options: Option[];
  isMulti?: boolean;
}

export const FormikSelect = ({
  field,
  form,
  options = [],
  isMulti = false,
  style = {},
  label = '',
  defaultValue = null,
  loading = false,
  getOptionDisabled = (option: Option) => {
    return false;
  },
  onChangeCallback,
}) => {
  const onChange = (_e: unknown, option: Option | Option[] | null) => {
    // (e, value) => {form.setFieldValue(field.name, value.value)}
    form.setFieldValue(
      field.name,
      isMulti
        ? (option as Option[]).map((item: Option) => item.value)
        : option
        ? (option as Option).value
        : null
    );

    if (onChangeCallback) {
      onChangeCallback(option);
    }

    // if (defaultValue) {
    //   console.log(JSON.stringify(defaultValue[0]));
    //   console.log(JSON.stringify(options[0]));
    // }
  };

  const getValue = () => {
    if (options) {
      return isMulti
        ? options.filter(
            (option: Option) => field.value.indexOf(option.value) >= 0
          )
        : options.find((option: Option) => option.value === field.value);
    }
    return isMulti ? [] : ('' as any);
  };

  return (
    <Autocomplete
      id="combo-box-demo"
      options={options}
      getOptionLabel={(option) => option.label}
      autoComplete
      autoHighlight
      style={style}
      value={getValue()}
      onChange={onChange}
      getOptionDisabled={getOptionDisabled}
      multiple={isMulti}
      renderInput={(params) => (
        <TextField {...params} label={label} variant="outlined" />
      )}
    />
  );
};

export default FormikSelect;
