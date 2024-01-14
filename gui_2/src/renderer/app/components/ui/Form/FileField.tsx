import React, { SyntheticEvent } from 'react';
import { useFormikContext } from 'formik';
import Icon from '@mui/material/Icon';
import IconButton from '@mui/material/IconButton';
import InputAdornment from '@mui/material/InputAdornment';
import type { DialogOptions } from '../../../../../interfaces';
import TextField from './TextField';
import electronApi, { activeWindow } from '../../../../../electronApi';

export type FileFieldProps = {
  label: string;
  name: string;
  required?: boolean;
  dialogOptions?: DialogOptions;
  separator?: string;
  helperText?: string;
};

export default function FileField({
  dialogOptions,
  separator,
  name,
  ...props
}: FileFieldProps) {
  const { setFieldValue } = useFormikContext();
  const multiple = dialogOptions?.properties?.includes('multiSelections');

  const handleClick = async () => {
    const { canceled, filePaths } = await electronApi.dialog.showOpenDialog(
      activeWindow()!,
      dialogOptions as any, //@TODO: fix this
    );
    if (!canceled) {
      if (filePaths) {
        await setFieldValue(
          name,
          multiple ? filePaths.join(separator) : filePaths.shift(),
        );
      }
    }
  };

  const handleMouseDown = (event: SyntheticEvent) => {
    event.preventDefault();
  };

  const endAdornment = (
    <InputAdornment position="end">
      <IconButton onClick={handleClick} onMouseDown={handleMouseDown}>
        <Icon className="fas fa-ellipsis-h" />
      </IconButton>
    </InputAdornment>
  );

  return <TextField name={name} {...props} InputProps={{ endAdornment }} />;
}

FileField.defaultProps = {
  required: false,
  dialogOptions: {},
  separator: ', ',
  helperText: undefined,
};
