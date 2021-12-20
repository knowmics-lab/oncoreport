/* eslint-disable @typescript-eslint/no-explicit-any */
import React, { useMemo, useState } from 'react';
import { useHistory, useParams } from 'react-router-dom';
import { createStyles, makeStyles } from '@material-ui/core/styles';
import { green } from '@material-ui/core/colors';
import {
  CircularProgress,
  FormGroup,
  FormHelperText,
  Grid,
  Paper,
  Typography,
} from '@material-ui/core';
import { ErrorMessage, Form, Formik, FormikHelpers } from 'formik';
import * as Yup from 'yup';
import { generatePath } from 'react-router';
import {
  JobRepository,
  PatientRepository,
  TransferManager,
  Utils,
} from '../../../../api';
import {
  Comparison,
  Genome,
  JobConfig,
  JobTypes,
  TypeOfNotification,
  UploadState,
} from '../../../../interfaces';
import { useService } from '../../../../reactInjector';
import SelectField from '../../ui/Form/SelectField';
import TextField from '../../ui/Form/TextField';
import Routes from '../../../../constants/routes.json';
import SwitchField from '../../ui/Form/SwitchField';
import Wizard from '../../ui/Wizard';
import FileSelector, { File } from '../../ui/FileSelector';
import UploadProgress from '../../ui/UploadProgress';
import { SubmitButton } from '../../ui/Button';
import { Capabilities } from '../../../../api/utils';
import useUpload from '../../../hooks/useUpload';
import useCapabilities from '../../../hooks/useCapabilities';
import useEffectOnce from '../../../hooks/useEffectOnce';
import useRepositoryFetchOne from '../../../hooks/useRepositoryFetchOne';
import useNotifications from '../../../hooks/useNotifications';

const useStyles = makeStyles((theme) =>
  createStyles({
    paper: {
      padding: 16,
    },
    formControl: {
      marginTop: theme.spacing(1),
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
    backdrop: {
      zIndex: theme.zIndex.drawer + 1,
      color: '#fff',
    },
    instructions: {
      marginTop: theme.spacing(1),
      marginBottom: theme.spacing(1),
      fontSize: theme.typography.fontSize,
    },
  })
);

const steps = [
  'Choose analysis type',
  'Set analysis preferences',
  'Select input files',
];

const ComparisonMap = {
  [Comparison.lt]: 'Less than (<)',
  [Comparison.lte]: 'Less than or equal to (<=)',
  [Comparison.gt]: 'Greater than (>)',
  [Comparison.gte]: 'Greater than or equal to (>=)',
};

type LocalData = {
  sample_code: string;
  name: string;
  type: JobTypes;
  inputType: 'fastq' | 'bam' | 'ubam' | 'vcf';
  threads: number;
  paired: boolean;
  genome: Genome;
  depthFilter: {
    comparison: Comparison;
    value: number;
  };
  alleleFractionFilter: {
    comparison: Comparison;
    value: number;
  };
  firstFile?: File;
  secondFile?: File;
  thirdFile?: File;
  fourthFile?: File;
};

// eslint-disable-next-line @typescript-eslint/ban-types
function CustomErrorMessage(props: {}) {
  return <FormHelperText error {...props} />;
}

type ThreadsTextProps = {
  capabilities: Capabilities | undefined;
  values: LocalData;
};

function ThreadsText({ capabilities, values }: ThreadsTextProps) {
  const allCores = capabilities?.numCores ?? 1;
  const { threads } = values;
  const maxMultiple = Math.floor(allCores / 3);
  const standardMessage = `Do not select more than ${maxMultiple} cores to allow for multiple concurrent analysis.`;
  if (threads <= maxMultiple) {
    return <>{standardMessage}</>;
  }
  return (
    <Typography color="error" component="span">
      {standardMessage}
    </Typography>
  );
}

function Step0({ capabilities, values }: ThreadsTextProps) {
  const classes = useStyles();
  return (
    <>
      <Typography className={classes.instructions}>
        Here you can input several features of the analysis and select its type.
        First, you need to choose a Sample code, which is used as an unique
        identifier. It is a good practice to input the same code used for sample
        identification in your lab. Nevertheless, it should be a string without
        any spaces (only letters, numbers, and dashes). Then, you can give a
        name to this analysis, select the type of input files (FASTQ, BAM, uBAM,
        VCF), the number of CPU cores to run the computation, and the type of
        the analysis (Tumor vs Normal or Tumor-only).
      </Typography>
      <TextField label="Sample Code" name="sample_code" required />
      <TextField label="Analysis Name" name="name" required />
      <SelectField
        label="Analysis Type"
        name="type"
        options={{
          [JobTypes.tumorNormal]: 'Tumor vs Normal',
          [JobTypes.tumorOnly]: 'Tumor-only',
        }}
        required
      />
      <SelectField
        label="Input Type"
        name="inputType"
        options={Utils.supportedAnalysisFileTypes()}
        required
      />
      <TextField
        label="Number of threads"
        name="threads"
        type="number"
        helperText={<ThreadsText capabilities={capabilities} values={values} />}
        required
      />
    </>
  );
}

type Step1Prop = {
  values: LocalData;
};

function Step1({ values }: Step1Prop) {
  const classes = useStyles();
  const { type } = values;

  return (
    <>
      <Typography className={classes.instructions}>
        Here you can set the main features of the chooses analysis. First you
        will be required to select the sequencing strategy (single or
        paired-end). Then you will be asked to choose the genome version (hg19
        or hg38), and the number of threads used for the analysis.
        {type === JobTypes.tumorOnly && (
          <>
            &nbsp;For a tumor-only analysis, you should also select the
            sequencing depth filter and the allele fraction filter (AF). The
            sequencing depth filter is the average number of reads generated by
            the NGS analysis for a DNA region. It depends on the NGS run, it can
            vary between different type of analysis, panels and tools. If you
            don&apos;t know what to do leave the default value. The allele
            fraction filter is the percentage of the mutated alleles, it helps
            understanding if a mutation is germline or somatic. We suggest an AF
            &gt; 0.3 for a liquid biopsy, and AF &lt; 0.4 for a solid biopsy.
          </>
        )}
      </Typography>
      <SwitchField label="Are reads paired-end?" name="paired" />
      <SelectField
        label="Analysis Type"
        name="genome"
        options={{
          [Genome.hg19]: 'Human hg19 genome',
          [Genome.hg38]: 'Human hg38 genome',
        }}
        required
      />
      {type === JobTypes.tumorOnly && (
        <>
          <FormGroup row className={classes.formControl}>
            <Grid
              container
              justifyContent="center"
              alignItems="baseline"
              spacing={1}
            >
              <Grid item xs={6} md={4}>
                <SelectField
                  label="Depth filter"
                  name="depthFilter.comparison"
                  options={ComparisonMap}
                />
              </Grid>
              <Grid item xs={6} md={2}>
                <TextField
                  label="Value"
                  name="depthFilter.value"
                  type="number"
                />
              </Grid>
              <Grid item xs={6} md={4}>
                <SelectField
                  label="Allele Fraction Filter"
                  name="alleleFractionFilter.comparison"
                  options={ComparisonMap}
                />
              </Grid>
              <Grid item xs={6} md={2}>
                <TextField
                  label="Value"
                  name="alleleFractionFilter.value"
                  type="number"
                />
              </Grid>
            </Grid>
          </FormGroup>
        </>
      )}
    </>
  );
}

type Step2Prop = {
  values: LocalData;
  uploadState: UploadState;
  setFieldValue: FormikHelpers<LocalData>['setFieldValue'];
};

function Step2({ values, uploadState, setFieldValue }: Step2Prop) {
  const classes = useStyles();
  const { type, inputType, paired } = values;
  const inputTypeString = Utils.supportedAnalysisFileTypes()[inputType];
  const multipleFiles = paired && inputType === 'fastq';
  const isTumorNormal = type === JobTypes.tumorNormal;
  const isVcf = inputType === 'vcf';
  const {
    isUploading,
    uploadFile,
    uploadedBytes,
    uploadedPercent,
    uploadTotal,
  } = uploadState;
  return (
    <>
      <Typography className={classes.instructions}>
        Here you can select the files that will be used for the analysis.
        {!isTumorNormal && (
          <>
            &nbsp;In this case, you will need to choose{' '}
            {multipleFiles ? 'two' : 'one'} {inputTypeString} file
            {multipleFiles ? 's' : ''} corresponding to a single sample.
          </>
        )}
        {isTumorNormal && !isVcf && (
          <>
            &nbsp;In this case, you will need to choose{' '}
            {multipleFiles ? 'two' : 'one'} {inputTypeString} file
            {multipleFiles ? 's' : ''} for the tumor sample, and{' '}
            {multipleFiles ? 'two' : 'one'} {inputTypeString} file
            {multipleFiles ? 's' : ''} for the normal sample.
          </>
        )}
        {isTumorNormal && isVcf && (
          <>
            &nbsp;In this case, you will need to choose one VCF file obtained
            from a Tumor vs Normal analysis.
          </>
        )}
      </Typography>
      <FormGroup row className={classes.formControl}>
        <Grid
          container
          justifyContent="space-evenly"
          alignItems="center"
          spacing={3}
        >
          <Grid item xs={2}>
            {!isVcf ? 'Tumor sample' : 'VCF file'}
          </Grid>
          <Grid item xs={multipleFiles && !isVcf ? 5 : 10}>
            <FileSelector
              value={values.firstFile ? [values.firstFile] : []}
              onFileRemove={() => setFieldValue('firstFile', undefined)}
              onFileAdd={(f) => setFieldValue('firstFile', f[0])}
              filters={Utils.analysisFileExtensions(inputType)}
              disabled={isUploading}
            />
            <ErrorMessage name="firstFile" component={CustomErrorMessage} />
          </Grid>
          {multipleFiles && !isVcf && (
            <Grid item xs={5}>
              <FileSelector
                value={values.secondFile ? [values.secondFile] : []}
                onFileRemove={() => setFieldValue('secondFile', undefined)}
                onFileAdd={(f) => setFieldValue('secondFile', f[0])}
                filters={Utils.analysisFileExtensions(inputType)}
                disabled={isUploading}
              />
              <ErrorMessage name="secondFile" component={CustomErrorMessage} />
            </Grid>
          )}
        </Grid>
      </FormGroup>
      {isTumorNormal && !isVcf && (
        <FormGroup row className={classes.formControl}>
          <Grid
            container
            justifyContent="space-evenly"
            alignItems="center"
            spacing={3}
          >
            <Grid item xs={2}>
              Normal sample
            </Grid>
            <Grid item xs={multipleFiles && !isVcf ? 5 : 10}>
              <FileSelector
                value={values.thirdFile ? [values.thirdFile] : []}
                onFileRemove={() => setFieldValue('thirdFile', undefined)}
                onFileAdd={(f) => setFieldValue('thirdFile', f[0])}
                filters={Utils.analysisFileExtensions(inputType)}
                disabled={isUploading}
              />
              <ErrorMessage name="thirdFile" component={CustomErrorMessage} />
            </Grid>
            {multipleFiles && !isVcf && (
              <Grid item xs={5}>
                <FileSelector
                  value={values.fourthFile ? [values.fourthFile] : []}
                  onFileRemove={() => setFieldValue('fourthFile', undefined)}
                  onFileAdd={(f) => setFieldValue('fourthFile', f[0])}
                  filters={Utils.analysisFileExtensions(inputType)}
                  disabled={isUploading}
                />
                <ErrorMessage
                  name="fourthFile"
                  component={CustomErrorMessage}
                />
              </Grid>
            )}
          </Grid>
        </FormGroup>
      )}
      <UploadProgress
        isUploading={isUploading}
        uploadFile={uploadFile}
        uploadedBytes={uploadedBytes}
        uploadedPercent={uploadedPercent}
        uploadTotal={uploadTotal}
      />
    </>
  );
}

function useValidationSchema(capabilities: Capabilities | undefined) {
  const cores = capabilities?.availableCores ?? 1;
  return Yup.object().shape({
    sample_code: Yup.string()
      .defined()
      .max(255)
      .matches(/^[A-Za-z0-9_]+$/, {
        message: 'The field must contain only letters, numbers, and dashes.',
      }),
    name: Yup.string().defined().max(255),
    type: Yup.mixed()
      .oneOf([JobTypes.tumorOnly, JobTypes.tumorNormal])
      .defined(),
    inputType: Yup.mixed()
      .oneOf(Object.keys(Utils.supportedAnalysisFileTypes()))
      .defined(),
    threads: Yup.number().defined().min(1).max(cores),
    paired: Yup.boolean().defined(),
    genome: Yup.mixed().oneOf([Genome.hg19, Genome.hg38]).defined(),
    depthFilter: Yup.mixed().when('type', {
      is: JobTypes.tumorOnly,
      then: Yup.object().shape({
        comparison: Yup.mixed().oneOf(Object.keys(ComparisonMap)).required(),
        value: Yup.number().required(),
      }),
      otherwise: Yup.object().notRequired(),
    }),
    alleleFractionFilter: Yup.mixed().when('type', {
      is: JobTypes.tumorOnly,
      then: Yup.object().shape({
        comparison: Yup.mixed().oneOf(Object.keys(ComparisonMap)).required(),
        value: Yup.number().required(),
      }),
      otherwise: Yup.object().notRequired(),
    }),
    firstFile: Yup.object().required(),
    secondFile: Yup.mixed().when(['inputType', 'paired'], {
      is: (inputType: string, paired: boolean) =>
        paired && !['vcf', 'bam', 'ubam'].includes(inputType),
      then: Yup.object().required(),
      otherwise: Yup.object().notRequired(),
    }),
    thirdFile: Yup.mixed().when(['type', 'inputType'], {
      is: (type: JobTypes, inputType: string) => {
        return type === JobTypes.tumorNormal && inputType !== 'vcf';
      },
      then: Yup.object().required(),
      otherwise: Yup.object().notRequired(),
    }),
    fourthFile: Yup.mixed().when(['type', 'inputType', 'paired'], {
      is: (type: JobTypes, inputType: string, paired: boolean) => {
        return (
          type === JobTypes.tumorNormal &&
          paired &&
          !['vcf', 'bam', 'ubam'].includes(inputType)
        );
      },
      then: Yup.object().required(),
      otherwise: Yup.object().notRequired(),
    }),
  });
}

function handleFileUpload(d: LocalData, parameters: JobConfig) {
  const toUpload: File[] = [];
  const { inputType, type, paired } = d;
  switch (inputType) {
    case 'vcf':
      if (!d.firstFile) throw new Error('Input file missing');
      parameters.vcf = d.firstFile.name;
      toUpload.push(d.firstFile);
      break;
    case 'bam':
      if (!d.firstFile) throw new Error('Input file missing');
      toUpload.push(d.firstFile);
      if (type === JobTypes.tumorOnly) {
        parameters.bam = d.firstFile.name;
      } else {
        parameters.tumor = {
          bam: d.firstFile.name,
        };
        if (!d.thirdFile) throw new Error('Normal input file missing');
        parameters.normal = {
          bam: d.thirdFile.name,
        };
        toUpload.push(d.thirdFile);
      }
      break;
    case 'ubam':
      if (!d.firstFile) throw new Error('Input file missing');
      toUpload.push(d.firstFile);
      if (type === JobTypes.tumorOnly) {
        parameters.ubam = d.firstFile.name;
      } else {
        parameters.tumor = {
          ubam: d.firstFile.name,
        };
        if (!d.thirdFile) throw new Error('Normal input file missing');
        parameters.normal = {
          ubam: d.thirdFile.name,
        };
        toUpload.push(d.thirdFile);
      }
      break;
    case 'fastq':
      if (!d.firstFile) throw new Error('Input file missing');
      toUpload.push(d.firstFile);
      if (type === JobTypes.tumorOnly) {
        parameters.fastq1 = d.firstFile.name;
        if (paired) {
          if (!d.secondFile) throw new Error('Second input file missing');
          parameters.fastq2 = d.secondFile.name;
          toUpload.push(d.secondFile);
        }
      } else {
        if (!d.thirdFile) throw new Error('Normal input file missing');
        toUpload.push(d.thirdFile);
        if (paired) {
          if (!d.secondFile) throw new Error('Second input file missing');
          if (!d.fourthFile)
            throw new Error('Second normal input file missing');
          parameters.tumor = {
            fastq1: d.firstFile.name,
            fastq2: d.secondFile.name,
          };
          parameters.normal = {
            fastq1: d.thirdFile.name,
            fastq2: d.fourthFile.name,
          };
          toUpload.push(d.secondFile);
          toUpload.push(d.fourthFile);
        } else {
          parameters.tumor = {
            fastq1: d.firstFile.name,
          };
          parameters.normal = {
            fastq1: d.thirdFile.name,
          };
        }
      }
      break;
    default:
      throw new Error('Unknown error');
  }
  return toUpload;
}

export default function NewAnalysisForm() {
  const classes = useStyles();
  const jobRepository = useService(JobRepository);
  const transferManager = useService(TransferManager);
  const history = useHistory();
  const { pushSimple } = useNotifications();
  const [uploadState, uploadCallbacks] = useUpload();
  const [submitting, setSubmitting] = useState(false);
  const { id } = useParams<{ id: string }>();

  const [loadingPatient, patient] = useRepositoryFetchOne(
    PatientRepository,
    +id
  );
  const [loadingCapabilities, capabilities, refresh] = useCapabilities();
  const validationSchema = useValidationSchema(capabilities);
  useEffectOnce(() => refresh());

  const loading = loadingPatient || loadingCapabilities;

  const jobData: LocalData = useMemo(
    () => ({
      inputType: 'fastq',
      name: '',
      paired: false,
      sample_code: '',
      threads: 1,
      type: JobTypes.tumorOnly,
      genome: Genome.hg38,
      alleleFractionFilter: { comparison: Comparison.gt, value: 0.3 },
      depthFilter: { comparison: Comparison.lt, value: 0 },
      firstFile: undefined,
      secondFile: undefined,
      thirdFile: undefined,
      fourthFile: undefined,
    }),
    []
  );

  return (
    <Paper elevation={1} className={classes.paper}>
      {loading || !patient ? (
        <>
          <Grid container justifyContent="center">
            <Grid item xs="auto">
              <CircularProgress color="inherit" />
            </Grid>
          </Grid>
          <Grid container justifyContent="center">
            <Grid item xs="auto">
              Please wait...
            </Grid>
          </Grid>
        </>
      ) : (
        <>
          <Typography variant="h5" component="h3">
            {`New analysis for ${patient.fullName}`}
          </Typography>
          <Typography component="p" />
          <Formik<LocalData>
            initialValues={jobData}
            validationSchema={validationSchema}
            onSubmit={async (d) => {
              try {
                setSubmitting(true);
                const { type } = d;
                const parameters: JobConfig = {
                  paired: d.paired,
                  genome: d.genome,
                  threads: d.threads,
                };
                const toUpload = handleFileUpload(d, parameters);
                if (type === JobTypes.tumorOnly) {
                  parameters.depthFilter = {
                    comparison: `${d.depthFilter.comparison}`,
                    value: d.depthFilter.value,
                  };
                  parameters.alleleFractionFilter = {
                    comparison: `${d.alleleFractionFilter.comparison}`,
                    value: d.alleleFractionFilter.value,
                  };
                }
                const job = await jobRepository.create({
                  sample_code: d.sample_code,
                  name: d.name,
                  type,
                  parameters,
                  patient: patient?.id,
                } as any);
                pushSimple(
                  `Job created...Starting upload!`,
                  TypeOfNotification.success
                );
                for (let i = 0; i < toUpload.length; i += 1) {
                  const file = toUpload[i];
                  uploadCallbacks.uploadStart(file.name);
                  // eslint-disable-next-line no-await-in-loop
                  await transferManager.upload(
                    job,
                    file.path,
                    file.name,
                    file.type,
                    uploadCallbacks.makeOnProgress()
                  );
                  uploadCallbacks.uploadEnd();
                }
                pushSimple(`Upload completed!`, TypeOfNotification.success);
                // await job.submit();
                pushSimple(`Job submitted!`, TypeOfNotification.success);
                history.push(
                  generatePath(Routes.JOBS_BY_PATIENT, {
                    id: patient?.id ?? 0,
                  })
                );
              } catch (e) {
                pushSimple(`An error occurred: ${e}`, TypeOfNotification.error);
                setSubmitting(false);
              }
            }}
          >
            {({ values, setFieldValue }) => (
              <Form>
                <Wizard
                  steps={steps}
                  submitButton={() => (
                    <SubmitButton isSaving={submitting} text="Start Analysis" />
                  )}
                  connectedFields={[
                    ['sample_code', 'name', 'type', 'inputType', 'threads'],
                    [
                      'paired',
                      'genome',
                      'depthFilter.comparison',
                      'depthFilter.value',
                      'alleleFractionFilter.comparison',
                      'alleleFractionFilter.value',
                    ],
                    ['firstFile', 'secondFile', 'thirdFile', 'fourthFile'],
                  ]}
                >
                  <Step0 values={values} capabilities={capabilities} />
                  <Step1 values={values} />
                  <Step2
                    values={values}
                    uploadState={uploadState}
                    setFieldValue={setFieldValue}
                  />
                </Wizard>
              </Form>
            )}
          </Formik>
        </>
      )}
    </Paper>
  );
}
