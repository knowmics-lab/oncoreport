<?php
/**
 * Oncoreport Web Service
 *
 * @author S. Alaimo, Ph.D. <alaimos at gmail dot com>
 */

namespace App\Jobs\Types;

use App\Exceptions\IgnoredException;
use App\Exceptions\ProcessingJobException;
use App\Jobs\Traits\UsesCommandLine;
use App\Jobs\Traits\UsesDrugsFile;
use App\Utils;
use Exception;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class TumorVsNormalAnalysisJobType extends AbstractJob
{

    use UsesCommandLine;
    use UsesDrugsFile;

    /**
     * Returns an array containing for each input parameter a help to detail its content and use.
     *
     * @return array
     */
    public static function parametersSpec(): array
    {
        return [
            'paired'          => 'A boolean value indicating whether the input if paired-end or not (OPTIONAL; default: FALSE)',
            'type'            => 'The type of input file (One of: fastq, bam, vcf, ubam; OPTIONAL; default: fastq)',
            'file1'           => 'The tumor first input filename (required)',
            'file2'           => 'The tumor second input filename (required if paired is TRUE and type is fastq)',
            'file3'           => 'The normal first input filename (required if type is not vcf)',
            'file4'           => 'The normal second input filename (required if paired is TRUE and type is fastq)',
            'genome'          => 'The genome version (hg19 or hg38; OPTIONAL; default: hg19)',
            'threads'         => 'The number of threads to use for the analysis (OPTIONAL; default: 1)',
            'callers'         => 'A list of enabled callers (Array of: mutect, lofreq, varscan; OPTIONAL; default: all)',
            'callers_options' => 'A list of options for each caller (Map of caller name => array of options; OPTIONAL; default: none). ' .
                'One parameter per array element (Example: the option "--test VALUE" should provided as ["--test","VALUE"].',
            'enable_options'  => [
                'mutect_downsampling'  => 'A boolean value indicating whether to enable the downsampling of the input file in Mutect2 (OPTIONAL; default: FALSE)',
                'varscan_all_variants' => 'A boolean value indicating whether to enable the use of all variants in VarScan2 (OPTIONAL; default: FALSE)',
            ],
            'depthFilter'     => [
                'comparison' => 'The type of comparison to be done for the sequencing depth filter (One of: lt, lte, gt, gte; OPTIONAL; default: lt)',
                'value'      => 'The value that will be used to filter the sequencing depth (OPTIONAL; default 0)',
            ],
        ];
    }

    /**
     * Returns an array containing for each output value an help detailing its use.
     *
     * @return array
     */
    public static function outputSpec(): array
    {
        return [
            'type'                    => 'The output type. The value must be "tumor-vs-normal".',
            'tumorBamRawFile'         => 'The path and url of the BAM file produced by BWA for the tumor sample',
            'tumorBamFinalFile'       => 'The path and url of the BAM file produced by BWA for the tumor sample, sorted and recalibrated through the GATK pipeline',
            'normalBamRawFile'        => 'The path and url of the BAM file produced by BWA for the normal sample',
            'normalBamFinalFile'      => 'The path and url of the BAM file produced by BWA for the normal sample, sorted and recalibrated through the GATK pipeline',
            'variantsRAWCallFile'     => 'The path and url of the VCF file produced by the callers',
            'variantsPASSOutputFile'  => 'The path and url of the VCF file produced by the callers after filtering',
            'variantsFINALOutputFile' => 'The path and url of the concatenated VCF file used for annotation',
            'textOutputFiles'         => 'The path and url of an archive with all results of the annotation process',
            'reportOutputFile'        => 'The path and url of the final report produced by this analysis',
            'reportZipFile'           => 'The path and url of the zip archive to download the final report produced by this analysis',
        ];
    }

    /**
     * Returns a description for this job
     *
     * @return string
     */
    public static function description(): string
    {
        return 'Runs the tumor vs normal analysis';
    }

    /**
     * @inheritDoc
     */
    public static function displayName(): string
    {
        return 'Tumor VS Normal';
    }

    /**
     * @inheritDoc
     */
    public static function validationSpec(Request $request): array
    {
        $parameters = (array)$request->get('parameters', []);

        return [
            'paired'                              => ['filled', 'boolean'],
            'type'                                => ['filled', Rule::in(['fastq', 'bam', 'vcf', 'ubam'])],
            'file1'                               => ['required', 'string'],
            'file2'                               => [
                'nullable',
                Rule::requiredIf(static function () use ($parameters) {
                    $paired = data_get($parameters, 'paired', false);
                    $type = data_get($parameters, 'type', 'fastq');

                    return $paired && $type === 'fastq';
                }),
            ],
            'file3'                               => [
                'nullable',
                Rule::requiredIf(static function () use ($parameters) {
                    $type = data_get($parameters, 'type', 'bam');

                    return $type !== 'vcf';
                }),
            ],
            'file4'                               => [
                'nullable',
                Rule::requiredIf(static function () use ($parameters) {
                    $paired = data_get($parameters, 'paired', false);
                    $type = data_get($parameters, 'type', 'fastq');

                    return $paired && $type === 'fastq';
                }),
            ],
            'callers'                             => ['filled', 'array'],
            'callers.*'                           => [Rule::in(['mutect', 'lofreq', 'varscan'])],
            'callers_options'                     => ['filled', 'array'],
            'callers_options.*'                   => ['array'],
            'callers_options.*.*'                 => ['string'],
            'enable_options'                      => ['filled', 'array'],
            'enable_options.mutect_downsampling'  => ['filled', 'boolean'],
            'enable_options.varscan_all_variants' => ['filled', 'boolean'],
            'genome'                              => ['filled', Rule::in(Utils::VALID_GENOMES)],
            'threads'                             => ['filled', 'integer'],
            'downsampling'                        => ['filled', 'boolean'],
            'depthFilter'                         => ['filled', 'array'],
            'depthFilter.comparison'              => ['filled', Rule::in(array_keys(Utils::VALID_FILTER_OPERATORS))],
            'depthFilter.value'                   => ['filled', 'numeric'],
        ];
    }

    /**
     * @inheritDoc
     */
    public static function patientInputState(): string
    {
        return self::PATIENT_REQUIRED;
    }

    /**
     * Handles all the computation for this job.
     * This function should throw a ProcessingJobException if something went wrong during the computation.
     * If no exceptions are thrown the job is considered as successfully completed.
     *
     * @throws \App\Exceptions\ProcessingJobException
     * @throws \Throwable
     */
    public function handle(): void
    {
        try {
            $this->log('Starting analysis.');
            $patient = $this->model->patient;
            throw_unless(
                $patient,
                new ProcessingJobException('This job is not tied to any patient. Unable to run the analysis.')
            );
            $paired = (bool)$this->model->getParameter('paired', false);
            $type = $this->model->getParameter('type', 'fastq');
            $file1 = $this->model->getParameter('file1');
            $file2 = $this->model->getParameter('file2');
            $file3 = $this->model->getParameter('file3');
            $file4 = $this->model->getParameter('file4');
            $callers = $this->model->getParameter('callers', ['mutect', 'lofreq', 'varscan']);
            $callersOptions = $this->model->getParameter('callers_options', []) + [
                    'mutect'  => [],
                    'lofreq'  => [],
                    'varscan' => [],
                ];
            $enableOptions = ((array)$this->model->getParameter('enable_options', [])) + [
                    'mutect_downsampling'  => false,
                    'varscan_all_variants' => false,
                ];
            if ($enableOptions['mutect_downsampling']) {
                $callersOptions['mutect'][] = '-d';
                $callersOptions['mutect'][] = '1';
            }
            if ($enableOptions['varscan_all_variants']) {
                $callersOptions['varscan'][] = '-H';
            }
            $genome = $this->model->getParameter('genome', Utils::VALID_GENOMES[0]);
            $threads = $this->model->getParameter('threads', 1);
            $depthFilterOperator = Utils::VALID_FILTER_OPERATORS[$this->model->getParameter(
                'depthFilter.comparison',
                'gt'
            )];
            $depthFilterValue = (double)$this->model->getParameter('depthFilter.value', 0);
            $depthFilter = sprintf("%s%.4f", $depthFilterOperator, $depthFilterValue);
            [$outputRelative, $outputAbsolute,] = $this->getJobFilePaths('output_');
            throw_if(
                !file_exists($outputAbsolute) && !mkdir($outputAbsolute, 0777, true) && !is_dir($outputAbsolute),
                ProcessingJobException::class,
                sprintf('Directory "%s" was not created', $outputAbsolute)
            );
            $drugsListFile = $this->createDrugsFile();
            $this->initCommand(
                'bash',
                self::scriptPath('pipeline_tumVSnormal.bash'),
                '-t',
                $type,
                '-1',
                $file1,
                '-P',
                $outputAbsolute,
                '-i',
                $patient->code,
                '-s',
                $patient->last_name,
                '-n',
                $patient->first_name,
                '-a',
                $patient->age,
                '-g',
                $patient->gender,
                '-d',
                $patient->primaryDisease->disease->doid,
                '-D',
                $drugsListFile,
                '-T',
                $threads,
                '-G',
                $genome,
                '-E',
                $depthFilter,
            )
                 ->arrayParameter('-C', $callers)
                 ->flagParameter('-p', $paired)
                 ->conditionalParameter('-2', $file2, $paired)
                 ->conditionalParameter('-3', $file3, $type !== 'vcf')
                 ->conditionalParameter('-4', $file4, $type === 'fastq' && $paired)
                 ->optionalParameter('-S', $patient->primaryDisease->stage_string)
                 ->arrayParameter('-M', $callersOptions['mutect'])
                 ->arrayParameter('-L', $callersOptions['lofreq'])
                 ->arrayParameter('-V', $callersOptions['varscan']);
            $model = $this->model;
            self::runCommand(
                $this->command(),
                $this->getAbsoluteJobDirectory(),
                null,
                static function ($type, $buffer) use ($model) {
                    $model->appendLog($buffer, false);
                },
                [
                    1   => 'An invalid parameter has been detected',
                    100 => 'Unable to create FASTQ directory',
                    101 => 'Unable to create working directories',
                    102 => 'Unable to convert tumor uBAM to FASTQ',
                    103 => 'Unable to convert normal uBAM to FASTQ',
                    104 => 'Unable to perform alignment of tumor sample',
                    105 => 'Unable to perform alignment of normal sample',
                    106 => 'Unable to pre-process tumor BAM',
                    107 => 'Unable to pre-process normal BAM',
                    108 => 'Unable to call variants with Mutect2',
                    109 => 'Unable to call variants with LoFreq',
                    110 => 'Unable to call variants with VarScan',
                    111 => 'Unable to concatenate variant calls',
                    112 => 'This should never happen!!',
                    113 => 'Unable to pre-process variants',
                    114 => 'Unable to prepare report input files',
                    115 => 'Unable to prepare ESMO guidelines',
                    116 => 'Unable to create report',
                    117 => 'Unable to clean up folders',
                    118 => 'Unable to filter variants',
                    119 => 'No PASS variants were found',
                ]
            );
            throw_unless(
                $this->fileExistsRelative($outputRelative . '/txt'),
                ProcessingJobException::class,
                'Unable to generate report intermediate files.'
            );
            throw_unless(
                $this->fileExistsRelative($outputRelative . '/report/index.html'),
                ProcessingJobException::class,
                'Unable to generate report output file.'
            );
            $this->log('Building intermediate archive');
            Utils::makeZipArchive(
                $this->absoluteJobPath($outputRelative . '/txt'),
                $this->absoluteJobPath($outputRelative . '/report/intermediate.zip')
            );
            $this->log('Building report archive');
            Utils::makeZipArchive(
                $this->absoluteJobPath($outputRelative . '/report'),
                $this->absoluteJobPath($outputRelative . '/report.zip')
            );
            $this->log('Writing output');
            $this->setOutput(
                [
                    'type'                    => Utils::TUMOR_NORMAL_TYPE,
                    'tumorBamRawFile'         => $this->getFilePathsForOutput(
                        $outputRelative . '/preprocess/tumor_annotated.bam'
                    ),
                    'tumorBamFinalFile'       => $this->getFilePathsForOutput(
                        $outputRelative . '/preprocess/tumor_ordered.bam'
                    ),
                    'normalBamRawFile'        => $this->getFilePathsForOutput(
                        $outputRelative . '/preprocess/normal_annotated.bam'
                    ),
                    'normalBamFinalFile'      => $this->getFilePathsForOutput(
                        $outputRelative . '/preprocess/normal_ordered.bam'
                    ),
                    'variantsRAWCallFile'     => $this->getFilePathsForOutput($outputRelative . '/variants_raw.tgz'),
                    'variantsPASSOutputFile'  => $this->getFilePathsForOutput($outputRelative . '/variants_pass.tgz'),
                    'variantsFINALOutputFile' => $this->getFilePathsForOutput($outputRelative . '/variants.vcf'),
                    'textOutputFiles'         => $this->getFilePathsForOutput(
                        $outputRelative . '/report/intermediate.zip'
                    ),
                    'reportOutputFile'        => $this->getFilePathsForOutput($outputRelative . '/report/index.html'),
                    'reportZipFile'           => $this->getFilePathsForOutput($outputRelative . '/report.zip'),
                ]
            );
            $this->log('Analysis completed.');
        } catch (Exception $e) {
            throw_if($e instanceof ProcessingJobException, $e);
            throw_if($e instanceof IgnoredException, $e);
            throw new ProcessingJobException('An error occurred during job processing.', 0, $e);
        }
    }

    /**
     * @inheritDoc
     */
    public function isInputValid(): bool
    {
        if (!in_array($this->model->getParameter('genome', Utils::VALID_GENOMES[0]), Utils::VALID_GENOMES, true)) {
            return false;
        }
        if ($this->model->getParameter('threads', 1) <= 0) {
            return false;
        }
        $paired = (bool)$this->model->getParameter('paired', false);
        $type = $this->model->getParameter('type', 'fastq');
        if (!$this->validateFileParameter('file1')) {
            return false;
        }
        if ($paired && $type === 'fastq' && !$this->validateFileParameter('file2')) {
            return false;
        }
        if ($type !== 'vcf' && !$this->validateFileParameter('file3')) {
            return false;
        }
        if ($paired && $type === 'fastq' && !$this->validateFileParameter('file4')) {
            return false;
        }

        return true;
    }

    /**
     * @inheritDoc
     */
    public function cleanupOnFail(): void
    {
        [, $outputAbsolute,] = $this->getJobFilePaths('output_');
        if (file_exists($outputAbsolute)) {
            Utils::recursiveChmod($outputAbsolute, 0777);
        }
    }
}
