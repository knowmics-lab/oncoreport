import React from 'react';
import { Field } from 'formik';
import FormControl from '@material-ui/core/FormControl';
import FormGroup from '@material-ui/core/FormGroup';
import FormControlLabel from '@material-ui/core/FormControlLabel';
import { Switch, SwitchProps as FormikSwitchProps } from 'formik-material-ui';
import useStyles from './hooks';

export interface SwitchProps
  extends Omit<FormikSwitchProps, 'form' | 'meta' | 'field'> {
  name: string;
  label: string;
}

export default function SwitchField({ label, ...props }: SwitchProps) {
  const classes = useStyles();
  return (
    <FormControl className={classes.formControl} fullWidth>
      <FormGroup>
        <FormControlLabel
          control={<Field component={Switch} type="checkbox" {...props} />}
          label={label}
        />
      </FormGroup>
    </FormControl>
  );
}
