import React, { useState } from 'react';
import {
  Button,
  CircularProgress,
  Collapse,
  FormGroup,
  Grid,
  styled,
  Typography,
} from '@mui/material';
import { Form, Formik } from 'formik';
import * as Yup from 'yup';
import TextField from '../components/ui/Form/TextField';
import SelectField from '../components/ui/Form/SelectField';
import FileField from '../components/ui/Form/FileField';
import SwitchField from '../components/ui/Form/SwitchField';
import { useContainer, useService } from '../../../reactInjector';
import { Settings as SettingsManager, ValidateConfig } from '../../../api';
import { ConfigObjectType, TypeOfNotification } from '../../../interfaces';
import useNotifications from '../hooks/useNotifications';
import styles from './styles';
import { is } from '../../../api/utils';
import StandardContainer from '../components/ui/StandardContainer';

const ButtonContainer = styled('div')(({ theme }) => ({
  margin: theme.spacing(1),
  position: 'relative',
}));

export default function Settings() {
  const injector = useContainer();
  const settings = useService(SettingsManager);
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
      const errorMessage = e instanceof Error ? e.message : 'Unknown error';
      pushSimple(
        `An error occurred: ${errorMessage}!`,
        TypeOfNotification.error,
      );
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
      then: (schema) => schema.required(),
      otherwise: (schema) => schema.notRequired(),
    }),
    containerName: Yup.string().when('local', {
      is: true,
      then: (schema) => schema.required(),
      otherwise: (schema) => schema.notRequired(),
    }),
    apiKey: Yup.string().when('local', {
      is: true,
      then: (schema) => schema.notRequired(),
      otherwise: (schema) => schema.required(),
    }),
  });

  return (
    <StandardContainer>
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
            <FormGroup row sx={styles.formControl}>
              <Grid container justifyContent="flex-end">
                <Grid item xs="auto">
                  <ButtonContainer>
                    <Button
                      type="submit"
                      variant="contained"
                      color="primary"
                      disabled={isSaving}
                    >
                      Save
                    </Button>
                    {isSaving && (
                      <CircularProgress size={24} sx={styles.buttonProgress} />
                    )}
                  </ButtonContainer>
                </Grid>
              </Grid>
            </FormGroup>
          </Form>
        )}
      </Formik>
    </StandardContainer>
  );
}
