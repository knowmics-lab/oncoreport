import React from 'react';
import { useField } from 'formik';
import { makeStyles } from '@mui/material/styles';
import FormControl from '@mui/material/FormControl';
import FormLabel from '@mui/material/FormLabel';
import FormHelperText from '@mui/material/FormHelperText';
import { Theme } from '@mui/material';

const formControlStyle = (theme: Theme) => ({
  width: '100%',
  margin: theme.spacing(1),
  minWidth: 120,
});

type CustomFieldProps = {
  name: string;
  label: string;
  children: React.ReactNode;
  required?: boolean;
  helperText?: React.ReactNode;
};

export default function CustomField({
  label,
  required,
  children,
  helperText,
  ...props
}: CustomFieldProps) {
  const [, { error, touched }] = useField(props);
  const hasError = !!(touched && error);
  const finalHelperText = hasError ? error : helperText;
  return (
    <FormControl
      fullWidth
      required={required}
      sx={formControlStyle}
      error={hasError}
    >
      <FormLabel sx={{ fontSize: '0.75rem' }}>{label}</FormLabel>
      {children}
      {!!finalHelperText && <FormHelperText>{finalHelperText}</FormHelperText>}
    </FormControl>
  );
}

CustomField.defaultProps = {
  required: false,
  helperText: null,
};
