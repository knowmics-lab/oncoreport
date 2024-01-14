/* eslint-disable react/jsx-no-useless-fragment */
import React from 'react';
import {
  Box,
  FormGroup,
  Grid,
  LinearProgress,
} from '@mui/material';
import byteSize from 'byte-size';
import { formControlStyle } from '../utils';

type Props = {
  isUploading: boolean;
  uploadFile: string;
  uploadedBytes: number;
  uploadedPercent: number;
  uploadTotal: number;
};

export default function UploadProgress({
  isUploading,
  uploadFile,
  uploadedBytes,
  uploadedPercent,
  uploadTotal,
}: Props) {
  return (
    <>
      {isUploading && (
        <FormGroup row sx={formControlStyle}>
          <Grid
            container
            justifyContent="center"
            alignItems="center"
            spacing={1}
          >
            <Grid item xs={12}>
              <Box fontWeight="fontWeightMedium">{`Uploading ${uploadFile}...`}</Box>
            </Grid>
            <Grid item xs={12}>
              <Grid
                container
                justifyContent="space-evenly"
                alignItems="center"
                spacing={1}
              >
                <Grid item xs={10}>
                  <LinearProgress
                    variant="determinate"
                    value={uploadedPercent}
                  />
                </Grid>
                <Grid item xs>
                  {`${byteSize(uploadedBytes)}/${byteSize(uploadTotal)}`}
                </Grid>
              </Grid>
            </Grid>
          </Grid>
        </FormGroup>
      )}
    </>
  );
}
