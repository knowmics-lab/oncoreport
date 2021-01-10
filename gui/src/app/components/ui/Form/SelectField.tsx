import React from 'react';
// import MenuItem from '@material-ui/core/MenuItem';
import { Field } from 'formik';
import {
  TextField as FormikTextField,
  TextFieldProps as FormikTextFieldProps,
} from 'formik-material-ui';
import useStyles from './hooks';
import { SimpleMapArray, SimpleMapType } from '../../../../interfaces';

const OPTION_MAPPER = ([k, v]: [string | number, string]) => (
  <option key={k} value={k}>
    {v}
  </option>
);
const EMPTY_OPTION = (emptyText: string) => (
  <option key="__EMPTY__" value="">
    {emptyText}
  </option>
);

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
  const classes = useStyles();
  const entries = Object.entries(options).map(OPTION_MAPPER);
  if (addEmpty) {
    entries.unshift(EMPTY_OPTION(emptyText || 'None'));
  }
  return (
    <Field
      className={classes.formControl}
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
