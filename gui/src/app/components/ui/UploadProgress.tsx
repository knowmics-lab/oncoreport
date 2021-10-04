import React from 'react';
import {
  Box,
  FormGroup,
  Grid,
  LinearProgress,
  createStyles,
  makeStyles,
} from '@material-ui/core';
import byteSize from 'byte-size';

const useStyles = makeStyles((theme) =>
  createStyles({
    formControl: {
      margin: theme.spacing(1),
      minWidth: 120,
    },
  })
);

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
  const classes = useStyles();
  return (
    <>
      {isUploading && (
        <FormGroup row className={classes.formControl}>
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
