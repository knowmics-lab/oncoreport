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
  enableMutect?: boolean;
  enableLoFreq?: boolean;
  enableVarScan?: boolean;
  downsampling?: boolean;
  allVariants?: boolean;
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

function VCFFilters({ type }: { type: JobTypes }) {
  const classes = useStyles();
  return (
    <>
      {type === JobTypes.tumorNormal && (
        <>
          <FormGroup row className={classes.formControl}>
            <Grid
              container
              justifyContent="center"
              alignItems="baseline"
              spacing={1}
            >
              <Grid item xs={4}>
                <SelectField
                  label="Depth filter"
                  name="depthFilter.comparison"
                  options={ComparisonMap}
                />
              </Grid>
              <Grid item xs={8}>
                <TextField
                  label="Value"
                  name="depthFilter.value"
                  type="number"
                />
              </Grid>
            </Grid>
          </FormGroup>
        </>
      )}
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
                  label="Variant Allele Fraction Filter"
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

function CallersSelector({ values }: Step1Prop) {
  const classes = useStyles();
  const { enableMutect, enableVarScan, allVariants } = values;
  return (
    <>
      <FormGroup row className={classes.formControl}>
        <Grid
          container
          justifyContent="center"
          alignItems="baseline"
          spacing={1}
        >
          <Grid item xs={6}>
            <SwitchField label="Enable Mutect2?" name="enableMutect" />
          </Grid>
          <Grid item xs={6}>
            {enableMutect && (
              <SwitchField label="Enable downsampling?" name="downsampling" />
            )}
          </Grid>
        </Grid>
        <Grid
          container
          justifyContent="center"
          alignItems="baseline"
          spacing={1}
        >
          <Grid item xs={6}>
            <SwitchField label="Enable LoFreq?" name="enableLoFreq" />
          </Grid>
          <Grid item xs={6} />
        </Grid>
        <Grid
          container
          justifyContent="center"
          alignItems="baseline"
          spacing={1}
        >
          <Grid item xs={6}>
            <SwitchField label="Enable VarScan?" name="enableVarScan" />
          </Grid>
          <Grid item xs={6}>
            {enableVarScan && (
              <SwitchField
                label={`Use all variants? ${
                  allVariants ? 'Yes' : 'High-confidence only'
                }`}
                name="allVariants"
              />
            )}
          </Grid>
        </Grid>
      </FormGroup>
    </>
  );
}

function Step1({ values }: Step1Prop) {
  const classes = useStyles();
  const { type, inputType } = values;

  return (
    <>
      <Typography className={classes.instructions}>
        Here you can set the main analysis parameters. First you need to select
        the sequencing strategy (single or paired-end). Then you can choose the
        genome version (hg19 or hg38)
        {inputType !== 'vcf' && <>, and the Variant Caller algorithms</>}.
        &nbsp;Finally, you can set the sequencing depth filter. When this filter
        is applied, we consider the variants with a depth matching the selected
        filter. Sequencing depth is the average number of reads covering a
        specific DNA region. Therefore, appropriate values depend on the NGS
        run, sequencing strategy, panel, and tools. If you do not know the
        correct value, you can leave the default settings.
        {type === JobTypes.tumorOnly && (
          <>
            &nbsp;For a tumor-only analysis, you should also select the variant
            allele fraction filter (AF). The variant allele fraction filter is
            the percentage of reads supporting the mutated allele. All variants
            matching the filter are inferred as germline. The others are
            considered somatic. We suggest an AF &gt; 0.3 for a liquid biopsy,
            and AF &gt; 0.4 for a solid tumor biopsy.
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
      {inputType !== 'vcf' && <CallersSelector values={values} />}
      <VCFFilters type={type} />
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
          {isVcf && (
            <Grid item xs={12}>
              <Typography>
                <b>Note:</b> The VCF file will be filtered using the
                &quot;FILTER&quot; column to keep PASS variants. If no PASS
                variants are found, this job will fail.
              </Typography>
            </Grid>
          )}
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
      .defined('Sample code is required')
      .max(255, 'Sample code is too long')
      .matches(/^[A-Za-z0-9_]+$/, {
        message: 'The field must contain only letters, numbers, and dashes.',
      }),
    name: Yup.string()
      .defined('Analysis name is required')
      .max(255, 'Analysis name is too long'),
    type: Yup.mixed()
      .oneOf(
        [JobTypes.tumorOnly, JobTypes.tumorNormal],
        'Invalid analysis type'
      )
      .defined('Analysis type is required'),
    inputType: Yup.mixed()
      .oneOf(
        Object.keys(Utils.supportedAnalysisFileTypes()),
        'Invalid input type'
      )
      .defined('Input type is required'),
    threads: Yup.number()
      .defined('Number of threads is required')
      .min(1, 'Number of threads is too low')
      .max(cores, `Maximum number of threads is ${cores}`),
    paired: Yup.boolean().defined('Paired/single is required'),
    genome: Yup.mixed()
      .oneOf([Genome.hg19, Genome.hg38], 'Invalid genome')
      .defined('Genome is required'),
    depthFilter: Yup.object().shape({
      comparison: Yup.mixed()
        .oneOf(Object.keys(ComparisonMap), 'Invalid comparison')
        .required('Comparison is required'),
      value: Yup.number().required('Value is required'),
    }),
    alleleFractionFilter: Yup.mixed().when('type', {
      is: JobTypes.tumorOnly,
      then: Yup.object().shape({
        comparison: Yup.mixed()
          .oneOf(Object.keys(ComparisonMap), 'Invalid comparison')
          .required('Comparison is required'),
        value: Yup.number().required('Value is required'),
      }),
      otherwise: Yup.object().notRequired(),
    }),
    firstFile: Yup.object().required('Tumor first file is required'),
    secondFile: Yup.mixed().when(['inputType', 'paired'], {
      is: (inputType: string, paired: boolean) =>
        paired && !['vcf', 'bam', 'ubam'].includes(inputType),
      then: Yup.object().required('Tumor second file is required'),
      otherwise: Yup.object().notRequired(),
    }),
    thirdFile: Yup.mixed().when(['type', 'inputType'], {
      is: (type: JobTypes, inputType: string) => {
        return type === JobTypes.tumorNormal && inputType !== 'vcf';
      },
      then: Yup.object().required('Normal first file is required'),
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
      then: Yup.object().required('Normal second file is required'),
      otherwise: Yup.object().notRequired(),
    }),
  });
}

function handleFileUpload(d: LocalData, parameters: JobConfig) {
  const toUpload: File[] = [];
  const { inputType, type, paired } = d;
  if (!d.firstFile) throw new Error('First tumor input file missing');
  parameters.file1 = d.firstFile.name;
  toUpload.push(d.firstFile);
  if (inputType === 'fastq' && paired) {
    if (!d.secondFile) throw new Error('Second tumor input file missing');
    parameters.file2 = d.secondFile.name;
    toUpload.push(d.secondFile);
  }
  if (type === JobTypes.tumorNormal && inputType !== 'vcf') {
    if (!d.thirdFile) throw new Error('First normal input file missing');
    parameters.file3 = d.thirdFile.name;
    toUpload.push(d.thirdFile);
    if (paired) {
      if (!d.fourthFile) throw new Error('Second normal input file missing');
      parameters.file4 = d.fourthFile.name;
      toUpload.push(d.fourthFile);
    }
  }
  return toUpload;
}

function getCallers(d: LocalData): string[] {
  let callers = ['mutect', 'lofreq', 'varscan'];
  if (!d.enableMutect) callers = callers.filter((c) => c !== 'mutect');
  if (!d.enableLoFreq) callers = callers.filter((c) => c !== 'lofreq');
  if (!d.enableVarScan) callers = callers.filter((c) => c !== 'varscan');
  return callers;
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
      depthFilter: { comparison: Comparison.gt, value: 0 },
      enableMutect: true,
      enableLoFreq: true,
      enableVarScan: true,
      downsampling: false,
      allVariants: false,
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
                const { type, inputType, allVariants, downsampling } = d;
                const parameters: JobConfig = {
                  paired: d.paired,
                  type: inputType,
                  genome: d.genome,
                  threads: d.threads,
                  callers: getCallers(d),
                  enable_options: {
                    mutect_downsampling: downsampling,
                    varscan_all_variants: allVariants,
                  },
                  depthFilter: {
                    comparison: `${d.depthFilter.comparison}`,
                    value: d.depthFilter.value,
                  },
                };
                const toUpload = handleFileUpload(d, parameters);
                if (type === JobTypes.tumorOnly) {
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
                      'enableMutect',
                      'enableLoFreq',
                      'enableVarScan',
                      'downsampling',
                      'allVariants',
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
