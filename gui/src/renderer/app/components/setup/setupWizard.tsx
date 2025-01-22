/* eslint-disable react/no-danger,no-console */
import React, { createRef, useEffect, useMemo, useState } from 'react';
import { Formik, Form } from 'formik';
import * as Yup from 'yup';
import {
  Button,
  Collapse,
  Link,
  CircularProgress,
  Backdrop,
  Paper,
  Box,
  Grid,
  Typography,
  LinearProgress,
  Theme,
} from '@mui/material';
import { DependencyContainer } from 'tsyringe';
import { useContainer, useService } from '../../../../reactInjector';
import { DockerManager, Settings, ValidateConfig } from '../../../../api';
import { logToHtml, runAsync } from '../utils';
import { SubmitButton } from '../ui/Button';
import { ConfigObjectType } from '../../../../interfaces';
import Wizard from '../ui/Wizard';
import SelectField from '../ui/Form/SelectField';
import TextField from '../ui/Form/TextField';
import SwitchField from '../ui/Form/SwitchField';
import FileField from '../ui/Form/FileField';
import electronApi from '../../../../electronApi';

const COSMIC_URL = 'https://cancer.sanger.ac.uk/cosmic/register';
const DEFAULT_START_PORT = 18080;

const instructionText = (theme: Theme) => ({
  marginTop: theme.spacing(1),
  marginBottom: theme.spacing(1),
  fontSize: theme.typography.fontSize,
});

const boldText = (theme: Theme) => ({
  fontWeight: theme.typography.fontWeightBold,
});

interface ExtendedConfig extends ConfigObjectType {
  cosmicUsername: string;
  cosmicPassword: string;
}

type Props = { values: ExtendedConfig };

function CosmicForm({ label }: { label?: boolean }) {
  return (
    <Grid
      container
      justifyContent="space-evenly"
      alignItems="center"
      spacing={2}
    >
      {label && (
        <Grid item md={2} sx={boldText}>
          COSMIC Account:
        </Grid>
      )}
      <Grid item md>
        <TextField label="Username" name="cosmicUsername" required />
      </Grid>
      <Grid item md>
        <TextField
          label="Password"
          name="cosmicPassword"
          type="password"
          required
        />
      </Grid>
    </Grid>
  );
}
CosmicForm.defaultProps = { label: false };

function Step0({ values }: Props) {
  return (
    <>
      <Typography sx={instructionText}>
        Here you can select whether you wish to use OncoReport with a local
        docker installation or with a remote server.
      </Typography>
      <SwitchField label="Use a local docker installation?" name="local" />
      <Collapse in={values.local}>
        <FileField
          label="Local storage path"
          name="dataPath"
          dialogOptions={{ properties: ['openDirectory'] }}
          helperText="Path where all data files will be stored"
        />
        <TextField label="Local container name" name="containerName" />
        <FileField
          label="Local docker socket"
          name="socketPath"
          dialogOptions={{ properties: ['openFile'], filters: [] }}
          helperText="The default value is automatically detected. Change only if you think this is wrong."
        />
      </Collapse>
    </>
  );
}

function Step1({ values }: Props) {
  const { local } = values;
  return (
    <>
      <Typography sx={instructionText}>
        Here you can configure the connection with OncoReport
        {local
          ? ' local docker container and your COSMIC account.'
          : ' remote server.'}
      </Typography>
      <Grid
        container
        justifyContent="space-around"
        alignItems="center"
        spacing={3}
      >
        <Grid item xs>
          <SelectField
            label="API Protocol"
            name="apiProtocol"
            options={{ http: 'http', https: 'https' }}
            required
          />
        </Grid>
        <Grid item xs>
          <TextField label="API Hostname" name="apiHostname" required />
        </Grid>
        <Grid item xs>
          <TextField label="API Port" name="apiPort" type="number" required />
        </Grid>
      </Grid>
      <Grid
        container
        justifyContent="space-around"
        alignItems="center"
        spacing={3}
      >
        <Grid item md>
          <TextField label="API Path" name="apiPath" required />
        </Grid>
        <Grid item md>
          <TextField label="Public Path" name="publicPath" required />
        </Grid>
      </Grid>
      {!local && <TextField label="API key" name="apiKey" />}
      {local && <CosmicForm label />}
    </>
  );
}

function Step2() {
  return (
    <Typography sx={instructionText}>
      All parameters have been set. Click &quot;Install&quot; to start the
      process.
    </Typography>
  );
}

function configFromExtendedConfig(c: ExtendedConfig): ConfigObjectType {
  return {
    apiHostname: c.apiHostname,
    apiKey: c.apiKey,
    apiPath: c.apiPath,
    apiPort: c.apiPort,
    apiProtocol: c.apiProtocol,
    autoStopDockerOnClose: false,
    configured: true,
    containerName: c.containerName,
    dataPath: c.dataPath,
    local: c.local,
    publicPath: c.publicPath,
    socketPath: c.socketPath,
  };
}

async function runSetup(
  values: ExtendedConfig,
  setLog: React.Dispatch<React.SetStateAction<string>>,
  settings: Settings,
  container: DependencyContainer,
) {
  try {
    const { cosmicUsername, cosmicPassword, local } = values;
    let newConfig = configFromExtendedConfig(values);
    let log = '';
    log += 'Starting installation process...\n';
    setLog(log);
    if (local) {
      const manager = container.resolve(DockerManager);
      manager.config = newConfig;
      if (!(await manager.hasImage())) {
        log += 'Container image not found...Downloading...\n';
        setLog(log);
        const state = await manager.pullImage(async (s) => {
          setLog(`${log}${s.toString()}`);
        });
        log += `${state.toString()}\n`;
      }
    }
    log += 'Validating configuration...\n';
    setLog(log);
    const validator = container.resolve(ValidateConfig);
    validator.newConfig = newConfig;
    newConfig = await validator.validate((m) => {
      log += m;
      setLog(log);
    });
    if (local) {
      log +=
        'Downloading Human Genome indexes and COSMIC database (this might take a while)...\n';
      setLog(log);
      const manager = container.resolve(DockerManager);
      manager.config = newConfig;
      await manager.runSetupScript(cosmicUsername, cosmicPassword, (m) => {
        log += m;
        setLog(log);
      });
    }
    log += 'Installation completed!\n';
    setLog(log);
    settings.saveConfig(newConfig);
    settings.saveConfig(newConfig);
  } catch (e) {
    setLog(
      (prev) =>
        `${prev}\n\n\u001b[0;31mAn error occurred: ${
          e instanceof Error ? e.message : 'Unknown error'
        }\u001b[0m\n`,
    );
  }
}

export default function SetupWizard() {
  const settings = useService(Settings);
  const container = useContainer();
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [firstStep, setFirstStep] = useState(true);
  const [advancedSetup, setAdvancedSetup] = useState(false);
  const [logContent, setLogContent] = useState('');
  const [freePort, setFreePort] = useState(DEFAULT_START_PORT);
  const logRef = createRef<HTMLDivElement>();

  useEffect(() => {
    runAsync(async () => {
      const port = await settings.findFreePort(DEFAULT_START_PORT);
      setFreePort(port);
      setLoading(false);
    });
  }, [settings]);

  useEffect(() => {
    if (saving && logContent && logRef.current) {
      logRef.current.scrollIntoView({ behavior: 'smooth' });
    }
  }, [logContent, logRef, saving]);

  const steps = [
    'Docker parameters',
    'Connection parameters',
    'Complete setup',
  ];

  const MySubmit = useMemo(
    () =>
      // eslint-disable-next-line react/no-unstable-nested-components,func-names
      function () {
        return <SubmitButton isSaving={saving} text="Install" />;
      },
    [saving],
  );

  const validationSchema = Yup.object().shape({
    local: Yup.boolean(),
    dataPath: Yup.string().when('local', {
      is: true,
      then: (s) => s.required(),
      otherwise: (s) => s.notRequired(),
    }),
    socketPath: Yup.string().notRequired(),
    containerName: Yup.string().when('local', {
      is: true,
      then: (s) => s.required(),
      otherwise: (s) => s.notRequired(),
    }),
    apiProtocol: Yup.string().required(),
    apiHostname: Yup.string().required(),
    apiPort: Yup.number().positive().integer().min(1).max(65535),
    apiPath: Yup.string().required(),
    publicPath: Yup.string().required(),
    apiKey: Yup.string().when('local', {
      is: true,
      then: (s) => s.notRequired(),
      otherwise: (s) => s.required(),
    }),
    cosmicUsername: Yup.string().when('local', {
      is: true,
      then: (s) => s.required(),
      otherwise: (s) => s.notRequired(),
    }),
    cosmicPassword: Yup.string().when('local', {
      is: true,
      then: (s) => s.required(),
      otherwise: (s) => s.notRequired(),
    }),
  });
  return (
    <>
      <Box>
        <Paper
          sx={(theme) => ({
            padding: theme.spacing(3, 2),
          })}
        >
          {!saving ? (
            <>
              <Typography variant="h5" component="h3">
                Setup Wizard
              </Typography>
              <Formik<ExtendedConfig>
                initialValues={{
                  ...settings.getDefaultConfig(freePort),
                  cosmicUsername: '',
                  cosmicPassword: '',
                }}
                onSubmit={async (v) => {
                  setSaving(true);
                  await runSetup(v, setLogContent, settings, container);
                }}
                validationSchema={validationSchema}
              >
                {({ values }) => (
                  <Form>
                    {firstStep && (
                      <>
                        <Typography sx={instructionText}>
                          Here you will setup your OncoReport instance through a
                          step-by-step procedure. Before you proceed with the
                          process, you should prepare your COSMIC account.
                          COSMIC is the world&apos;s largest and most
                          comprehensive resource for exploring the impact of
                          somatic mutations in human cancer. It is a fundamental
                          part of Oncoreport annotation procedure. If you do not
                          have an account, you can create one by{' '}
                          <Link
                            href={COSMIC_URL}
                            onClick={(
                              e: React.MouseEvent<HTMLAnchorElement>,
                            ) => {
                              e.preventDefault();
                              electronApi.shell
                                // eslint-disable-next-line @typescript-eslint/ban-ts-comment
                                // @ts-ignore
                                .openExternal(e.target.href)
                                .catch(console.error);
                            }}
                          >
                            clicking here
                          </Link>
                          .
                        </Typography>
                        <Grid
                          container
                          spacing={1}
                          direction="column"
                          alignItems="center"
                        >
                          <Grid item>
                            <Typography sx={boldText}>
                              Choose setup mode
                            </Typography>
                          </Grid>
                          <Grid item>
                            <Button
                              type="button"
                              variant="contained"
                              color="primary"
                              onClick={(e) => {
                                e.preventDefault();
                                setAdvancedSetup(false);
                                setFirstStep(false);
                              }}
                              disabled={saving}
                            >
                              Express setup
                            </Button>
                          </Grid>
                          <Grid item>
                            <Button
                              type="button"
                              variant="contained"
                              color="primary"
                              onClick={(e) => {
                                e.preventDefault();
                                setAdvancedSetup(true);
                                setFirstStep(false);
                              }}
                              disabled={saving}
                            >
                              Custom setup
                            </Button>
                          </Grid>
                        </Grid>
                      </>
                    )}
                    {!firstStep && advancedSetup && (
                      <Wizard
                        steps={steps}
                        submitButton={MySubmit}
                        connectedFields={[
                          ['local', 'dataPath', 'socketPath', 'containerName'],
                          [
                            'apiProtocol',
                            'apiHostname',
                            'apiPort',
                            'apiPath',
                            'publicPath',
                            'apiKey',
                            'cosmicUsername',
                            'cosmicPassword',
                          ],
                          [],
                        ]}
                      >
                        <Step0 values={values} />
                        <Step1 values={values} />
                        <Step2 />
                      </Wizard>
                    )}
                    {!firstStep && !advancedSetup && (
                      <>
                        <Typography sx={instructionText}>
                          Please, insert here your COSMIC credentials (username
                          and password), and click &quot;Install&quot; to start
                          the process. If you do not have a COSMIC account, you
                          can create one by{' '}
                          <Link
                            href={COSMIC_URL}
                            onClick={(
                              e: React.MouseEvent<HTMLAnchorElement>,
                            ) => {
                              e.preventDefault();
                              electronApi.shell
                                // eslint-disable-next-line @typescript-eslint/ban-ts-comment
                                // @ts-ignore
                                .openExternal(e.target.href)
                                .catch(console.error);
                            }}
                          >
                            clicking here
                          </Link>
                          .
                        </Typography>
                        <Grid
                          container
                          spacing={1}
                          direction="column"
                          alignItems="center"
                        >
                          <Grid item>
                            <CosmicForm />
                          </Grid>
                          <Grid item>{MySubmit()}</Grid>
                        </Grid>
                      </>
                    )}
                  </Form>
                )}
              </Formik>
            </>
          ) : (
            <>
              <Typography variant="h5" component="h3">
                Installing...
              </Typography>
              <Box>
                <div
                  style={{
                    fontFamily: "'Courier New', monospace",
                    color: 'white',
                    background: 'black',
                    width: '100%',
                    overflowY: 'auto',
                    wordBreak: 'break-all',
                  }}
                  dangerouslySetInnerHTML={{ __html: logToHtml(logContent) }}
                />
                <div ref={logRef} />
              </Box>
              <LinearProgress />
            </>
          )}
        </Paper>
      </Box>
      <Backdrop
        sx={(theme) => ({
          zIndex: theme.zIndex.drawer + 1,
          color: '#fff',
        })}
        open={loading}
      >
        <CircularProgress color="inherit" />
      </Backdrop>
    </>
  );
}
