import React, { useState } from 'react';
import { createStyles, makeStyles } from '@material-ui/core/styles';
import {
  Button,
  CircularProgress,
  Collapse,
  FormGroup,
  Grid,
  Paper,
  Typography,
} from '@material-ui/core';
import { green } from '@material-ui/core/colors';
import { Form, Formik } from 'formik';
import * as Yup from 'yup';
import { is } from 'electron-util';
import TextField from '../UI/Form/TextField';
import SelectField from '../UI/Form/SelectField';
import FileField from '../UI/Form/FileField';
import SwitchField from '../UI/Form/SwitchField';
import { useContainer, useService } from '../../../reactInjector';
import { Settings as SettingsManager, ValidateConfig } from '../../../api';
import { ConfigObjectType, TypeOfNotification } from '../../../interfaces';
import { useNotifications } from '../UI/hooks';

const useStyles = makeStyles((theme) =>
  createStyles({
    paper: {
      padding: 16,
    },
    formControl: {
      margin: theme.spacing(1),
      minWidth: 120,
    },
    buttonWrapper: {
      margin: theme.spacing(1),
      position: 'relative',
    },
    buttonProgress: {
      color: green[500],
      position: 'absolute',
      top: '50%',
      left: '50%',
      marginTop: -12,
      marginLeft: -12,
    },
  })
);

export default function Settings() {
  const injector = useContainer();
  const settings = useService(SettingsManager);
  const classes = useStyles();
  const [isSaving, setIsSaving] = useState(false);
  const { pushSimple } = useNotifications();

  const formSubmit = async (values: ConfigObjectType) => {
    setIsSaving(true);
    try {
      const validator = injector.resolve(ValidateConfig);
      validator.newConfig = {
        ...values,
        configured: true,
        socketPath:
          values.socketPath ||
          (is.windows ? '//./pipe/docker_engine' : '/var/run/docker.sock'),
      };
      const newConfig = await validator.validate();
      settings.saveConfig(newConfig);
      pushSimple('Settings saved!', TypeOfNotification.success);
      setIsSaving(false);
    } catch (e) {
      pushSimple(`An error occurred: ${e.message}!`, TypeOfNotification.error);
      setIsSaving(false);
      throw e;
    }
  };

  const validationSchema = Yup.object().shape({
    apiProtocol: Yup.string().required(),
    apiHostname: Yup.string().required(),
    apiPort: Yup.number().positive().integer().min(1).max(65535),
    apiPath: Yup.string().required(),
    publicPath: Yup.string().required(),
    local: Yup.boolean(),
    dataPath: Yup.string().when('local', {
      is: true,
      then: Yup.string().required(),
      otherwise: Yup.string().notRequired(),
    }),
    // socketPath: Yup.string().when('local', {
    //   is: true,
    //   then: Yup.string().notRequired(),
    //   otherwise: Yup.string().notRequired(),
    // }),
    containerName: Yup.string().when('local', {
      is: true,
      then: Yup.string().required(),
      otherwise: Yup.string().notRequired(),
    }),
    apiKey: Yup.string().when('local', {
      is: true,
      then: Yup.string().notRequired(),
      otherwise: Yup.string().required(),
    }),
  });

  return (
    <Paper elevation={1} className={classes.paper}>
      <Typography variant="h5" component="h3">
        Settings
      </Typography>
      <Typography component="p" />
      <Formik
        initialValues={settings.getConfig()}
        validationSchema={validationSchema}
        onSubmit={formSubmit}
      >
        {({ values }) => (
          <Form>
            <Grid container spacing={2}>
              <Grid item md>
                <SelectField
                  label="API Protocol"
                  name="apiProtocol"
                  options={{ http: 'http', https: 'https' }}
                  required
                />
              </Grid>
              <Grid item md>
                <TextField label="API Hostname" name="apiHostname" required />
              </Grid>
              <Grid item md>
                <TextField
                  label="API Port"
                  name="apiPort"
                  type="number"
                  required
                />
              </Grid>
            </Grid>
            <Grid container spacing={2}>
              <Grid item md>
                <TextField label="API Path" name="apiPath" required />
              </Grid>
              <Grid item md>
                <TextField label="Public Path" name="publicPath" required />
              </Grid>
            </Grid>
            <SwitchField label="Is docker installed locally?" name="local" />
            <Collapse in={values.local}>
              <Grid container spacing={2}>
                <Grid item md>
                  <FileField
                    label="Local container storage path"
                    name="dataPath"
                    dialogOptions={{ properties: ['openDirectory'] }}
                  />
                </Grid>
                <Grid item md>
                  <TextField
                    label="Local container name"
                    name="containerName"
                  />
                </Grid>
                <Grid item md>
                  <FileField
                    label="Local docker socket"
                    name="socketPath"
                    dialogOptions={{ properties: ['openFile'], filters: [] }}
                  />
                </Grid>
              </Grid>
            </Collapse>
            <TextField label="API key" name="apiKey" />
            <FormGroup row className={classes.formControl}>
              <Grid container justify="flex-end">
                <Grid item xs="auto">
                  <div className={classes.buttonWrapper}>
                    <Button
                      type="submit"
                      variant="contained"
                      color="primary"
                      disabled={isSaving}
                    >
                      Save
                    </Button>
                    {isSaving && (
                      <CircularProgress
                        size={24}
                        className={classes.buttonProgress}
                      />
                    )}
                  </div>
                </Grid>
              </Grid>
            </FormGroup>
          </Form>
        )}
      </Formik>
    </Paper>
  );
}
