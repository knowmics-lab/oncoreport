import React from 'react';
import { Field } from 'formik';
import {
  TextField as FormikTextField,
  TextFieldProps as FormikTextFieldProps,
} from 'formik-mui';
import { SimpleMapArray, SimpleMapType } from '../../../../../interfaces';
import { formControlStyle } from '../../utils';

function OPTION_MAPPER([k, v]: [string | number, string]) {
  return (
    <option key={k} value={k}>
      {v}
    </option>
  );
}
function EMPTY_OPTION(emptyText: string) {
  return (
    <option key="__EMPTY__" value="">
      {emptyText}
    </option>
  );
}

export interface SelectProps
  extends Omit<
    FormikTextFieldProps,
    'select' | 'form' | 'meta' | 'field' | 'fullWidth'
  > {
  name: string;
  multiple?: boolean;
  emptyText?: string;
  addEmpty?: boolean;
  options: SimpleMapType<string> | SimpleMapArray<string>;
}

export default function SelectField({
  options,
  addEmpty,
  emptyText,
  multiple,
  SelectProps,
  InputLabelProps,
  ...props
}: SelectProps) {
  const entries = Object.entries(options).map(OPTION_MAPPER);
  if (addEmpty) {
    entries.unshift(EMPTY_OPTION(emptyText || 'None'));
  }
  return (
    <Field
      component={FormikTextField}
      type="text"
      select
      fullWidth
      SelectProps={{
        ...(SelectProps || {}),
        native: !multiple,
        multiple: multiple || false,
      }}
      InputLabelProps={{
        ...(InputLabelProps || {}),
        shrink: true,
      }}
      sx={formControlStyle}
      {...props}
    >
      {entries}
    </Field>
  );
}

SelectField.defaultProps = {
  emptyText: 'None',
  addEmpty: false,
  multiple: false,
};
