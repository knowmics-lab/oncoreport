import React from 'react';
import { Field } from 'formik';
import {
  TextField as FormikTextField,
  TextFieldProps as FormikTextFieldProps,
} from 'formik-material-ui';
import useStyles from './hooks';

export interface TextFieldProps
  extends Omit<FormikTextFieldProps, 'form' | 'meta' | 'field' | 'fullWidth'> {
  name: string;
}

export default function TextField(props: TextFieldProps) {
  const classes = useStyles();
  return (
    <Field
      className={classes.formControl}
      component={FormikTextField}
      fullWidth
      {...props}
    />
  );
}
