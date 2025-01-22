import React from 'react';
import { Field } from 'formik';
import {
  TextField as FormikTextField,
  TextFieldProps as FormikTextFieldProps,
} from 'formik-mui';
import { formControlStyle } from '../../utils';

export interface TextFieldProps
  extends Omit<FormikTextFieldProps, 'form' | 'meta' | 'field' | 'fullWidth'> {
  name: string;
}

export default function TextField(props: TextFieldProps) {
  return (
    <Field
      sx={formControlStyle}
      component={FormikTextField}
      fullWidth
      {...props}
    />
  );
}
