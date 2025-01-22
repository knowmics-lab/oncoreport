import React from 'react';
import { Field } from 'formik';
import FormControl from '@mui/material/FormControl';
import FormGroup from '@mui/material/FormGroup';
import FormControlLabel from '@mui/material/FormControlLabel';
import { Switch, SwitchProps as FormikSwitchProps } from 'formik-mui';
import { formControlStyle } from '../../utils';

export interface SwitchProps
  extends Omit<FormikSwitchProps, 'form' | 'meta' | 'field'> {
  name: string;
  label: string;
}

export default function SwitchField({ label, ...props }: SwitchProps) {
  return (
    <FormControl sx={formControlStyle} fullWidth>
      <FormGroup>
        <FormControlLabel
          control={<Field component={Switch} type="checkbox" {...props} />}
          label={label}
        />
      </FormGroup>
    </FormControl>
  );
}
