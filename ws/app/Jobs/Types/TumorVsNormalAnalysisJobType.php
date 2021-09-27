<?php
/**
 * Oncoreport Web Service
 *
 * @author S. Alaimo, Ph.D. <alaimos at gmail dot com>
 */

namespace App\Jobs\Types;

use App\Exceptions\IgnoredException;
use App\Exceptions\ProcessingJobException;
use App\Utils;
use Exception;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class TumorVsNormalAnalysisJobType extends AbstractJob
{

    /**
     * Returns an array containing for each input parameter an help detailing its content and use.
     *
     * @return array
     */
    public static function parametersSpec(): array
    {
        return [
            'paired'  => 'A boolean value indicating whether the input if paired-end or not (OPTIONAL; default: FALSE)',
            'tumor'   => [
                'fastq1' => 'The first FASTQ filename for the tumor sample (Required if no uBAM, BAM, or VCF files are used)',
                'fastq2' => 'The second FASTQ filename for the tumor sample (Required if the input is paired-end and no uBAM, BAM, or VCF files are used)',
                'ubam'   => 'The uBAM filename for the tumor sample (Required if no FASTQ, BAM, or VCF files are used)',
                'bam'    => 'The BAM filename for the tumor sample (Required if no FASTQ, uBAM, or VCF files are used)',
            ],
            'normal'  => [
                'fastq1' => 'The first FASTQ filename for the normal sample (Required if no uBAM, BAM, or VCF files are used)',
                'fastq2' => 'The second FASTQ filename for the normal sample (Required if the input is paired-end and no uBAM, BAM, or VCF files are used)',
                'ubam'   => 'The uBAM filename for the normal sample (Required if no FASTQ, BAM, or VCF files are used)',
                'bam'    => 'The BAM filename for the normal sample (Required if no FASTQ, uBAM, or VCF files are used)',
            ],
            'vcf'     => 'A VCF filename for a custom tumor-vs-normal analysis (Required if no FASTQ, uBAM, or BAM files are used)',
            'genome'  => 'The genome version (hg19 or hg38; OPTIONAL; default: hg19)',
            'threads' => 'The number of threads to use for the analysis (OPTIONAL; default: 1)',
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
            'type'                => Utils::TUMOR_NORMAL_TYPE,
            'tumorBamOutputFile'  => 'The path and url of the tumor BAM file produced by this analysis',
            'normalBamOutputFile' => 'The path and url of the normal BAM file produced by this analysis',
            'vcfOutputFile'       => 'The path and url of the VCF file produced by this analysis',
            'vcfPASSOutputFile'   => 'The path and url of the VCF file produced by this analysis filtered to keep only PASS variants',
            'textOutputFiles'     => 'The path and url of an archive containing all text files generated by annotating the VCF file',
            'reportOutputFile'    => 'The path and url of the final report produced by this analysis',
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
            'paired'        => ['filled', 'boolean'],
            'tumor'         => ['required', 'array'],
            'tumor.fastq1'  => [
                'nullable',
                'required_without_all:parameters.tumor.ubam,parameters.tumor.bam,parameters.vcf',
            ],
            'tumor.fastq2'  => [
                'nullable',
                Rule::requiredIf(
                    static function () use ($parameters) {
                        $fastq = data_get($parameters, 'tumor.fastq1');

                        return ((bool)($parameters['paired'] ?? false)) && !empty($fastq);
                    }
                ),
            ],
            'tumor.ubam'    => [
                'nullable',
                'required_without_all:parameters.tumor.fastq1,parameters.tumor.bam,parameters.vcf',
            ],
            'tumor.bam'     => [
                'nullable',
                'required_without_all:parameters.tumor.fastq1,parameters.tumor.ubam,parameters.vcf',
            ],
            'normal'        => ['required', 'array'],
            'normal.fastq1' => [
                'nullable',
                'required_with:parameters.tumor.fastq1',
                'required_without_all:parameters.normal.ubam,parameters.normal.bam,parameters.vcf',
            ],
            'normal.fastq2' => [
                'nullable',
                'required_with:tumor.fastq2',
                Rule::requiredIf(
                    static function () use ($parameters) {
                        $fastq = data_get($parameters, 'normal.fastq1');

                        return ((bool)($parameters['paired'] ?? false)) && !empty($fastq);
                    }
                ),
            ],
            'normal.ubam'   => [
                'nullable',
                'required_with:parameters.tumor.ubam',
                'required_without_all:parameters.normal.fastq1,parameters.normal.bam,parameters.vcf',
            ],
            'normal.bam'    => [
                'nullable',
                'required_with:parameters.tumor.bam',
                'required_without_all:parameters.normal.fastq1,parameters.normal.ubam,parameters.vcf',
            ],
            'vcf'           => [
                'nullable',
                'required_without_all:parameters.tumor.fastq1,parameters.tumor.bam,parameters.tumor.ubam,parameters.normal.fastq1,parameters.normal.bam,parameters.normal.ubam',
            ],
            'genome'        => ['filled', Rule::in(Utils::VALID_GENOMES)],
            'threads'       => ['filled', 'integer'],
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
            $tumorFastq1 = $this->model->getParameter('tumor.fastq1');
            $tumorFastq2 = $this->model->getParameter('tumor.fastq2');
            $tumorUbam = $this->model->getParameter('tumor.ubam');
            $tumorBam = $this->model->getParameter('tumor.bam');
            $normalFastq1 = $this->model->getParameter('normal.fastq1');
            $normalFastq2 = $this->model->getParameter('normal.fastq2');
            $normalUbam = $this->model->getParameter('normal.ubam');
            $normalBam = $this->model->getParameter('normal.bam');
            $vcf = $this->model->getParameter('vcf');
            $genome = $this->model->getParameter('genome', Utils::VALID_GENOMES[0]);
            $threads = $this->model->getParameter('threads', 1);
            [$outputRelative, $outputAbsolute,] = $this->getJobFilePaths('output_');
            throw_if(
                !file_exists($outputAbsolute) && !mkdir($outputAbsolute, 0777, true) && !is_dir($outputAbsolute),
                ProcessingJobException::class,
                sprintf('Directory "%s" was not created', $outputAbsolute)
            );
            $command = [
                'bash',
                self::scriptPath('pipeline_tumVSnormal.bash'),
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
                '-t',
                $patient->disease->name,
                '-pp',
                $outputAbsolute,
                '-th',
                $threads,
                '-gn',
                $genome,
                '-st',
                $patient->site->name,
                '-sg',
                $patient->stage(),
                '-d_path',
                realpath(env('DATABASES_PATH') . env('DRUGS_FILE')),
            ];

            if ($patient->city != null){
                $command = [...$command, '-c', $patient->city];
            }
            if ($patient->telephone != null){
                $command = [...$command, '-ph', $patient->telephone];
            }

            if ($this->fileExists($vcf)) {
                $command = [...$command, '-v', $vcf];
            } elseif ($this->fileExists($tumorBam) && $this->fileExists($normalBam)) {
                $command = [
                    ...$command,
                    '-bt',
                    $tumorBam,
                    '-bn',
                    $normalBam,
                ];
            } elseif ($this->fileExists($tumorUbam) && $this->fileExists($normalUbam)) {
                $command = [
                    ...$command,
                    '-ubt',
                    $tumorUbam,
                    '-ubn',
                    $normalUbam,
                    '-pr',
                    $paired ? 'yes' : 'no',
                ];
            } elseif ($this->fileExists($tumorFastq1) && $this->fileExists($normalFastq1)) {
                $command = [
                    ...$command,
                    '-fq1',
                    $tumorFastq1,
                    '-nm1',
                    $normalFastq1,
                ];
                if ($paired && $this->fileExists($tumorFastq2) && $this->fileExists($normalFastq2)) {
                    $command = [
                        ...$command,
                        '-fq2',
                        $tumorFastq2,
                        '-nm2',
                        $normalFastq2,
                    ];
                } else {
                    throw new ProcessingJobException(
                        'Unable to validate second fastq files with a paired-end analysis.'
                    );
                }
            } else {
                throw new ProcessingJobException('No valid input files have been specified.');
            }
            $model = $this->model;
            try {
                self::runCommand(
                    $command,
                    $this->getAbsoluteJobDirectory(),
                    null,
                    static function ($type, $buffer) use ($model) {
                        $model->appendLog($buffer, false);
                    },
                    [
                        1   => 'An invalid parameter has been detected',
                        101 => 'Unable to convert tumor uBAM to FASTQ',
                        102 => 'Unable to trim tumor FASTQ file',
                        103 => 'Unable to align tumor FASTQ file',
                        104 => 'Unable to add read groups to tumor BAM file',
                        105 => 'Unable to sort tumor BAM file',
                        106 => 'Unable to reorder tumor BAM file',
                        107 => 'Unable to remove duplicates from tumor BAM file',
                        108 => 'Unable to convert normal uBAM to FASTQ',
                        109 => 'Unable to trim normal FASTQ file',
                        110 => 'Unable to align normal FASTQ file',
                        111 => 'Unable to add read groups to normal BAM file',
                        112 => 'Unable to sort normal BAM file',
                        113 => 'Unable to reorder normal BAM file',
                        114 => 'Unable to remove duplicates from normal BAM file',
                        115 => 'Unable to call variants',
                        116 => 'Unable to filter variants',
                        117 => 'Unable to select PASS variants',
                        118 => 'Unable to copy input VCF file',
                        119 => 'Unable to prepare variants file for annotation',
                        120 => 'Unable to prepare input file for annotation',
                        121 => 'Unable to build report output',
                        122 => 'Unable to clean unused folders',
                        200 => Utils::IGNORED_ERROR_CODE,
                    ]
                );
            } catch (IgnoredException $e) {
                $this->log("\n\nUnable to produce a report since no mutations have been found in the input data!");
                throw $e;
            }
            throw_unless(
                $this->fileExistsRelative($outputRelative . '/txt'),
                ProcessingJobException::class,
                'Unable to generate report intermediate files.'
            );
            throw_unless(
                $this->fileExistsRelative($outputRelative . '/output/report.html'),
                ProcessingJobException::class,
                'Unable to generate report output file.'
            );
            $this->log('Building intermediate archive');
            Utils::makeZipArchive(
                $this->absoluteJobPath($outputRelative . '/txt'),
                $this->absoluteJobPath($outputRelative . '/output/intermediate.zip')
            );
            $this->log('Writing output');
            $this->setOutput(
                [
                    'tumorBamOutputFile'  => $this->getFilePathsForOutput(
                        $outputRelative . '/mark_dup_tumor/nodup.bam'
                    ),
                    'normalBamOutputFile' => $this->getFilePathsForOutput(
                        $outputRelative . '/mark_dup_normal/nodup.bam'
                    ),
                    'vcfOutputFile'       => $this->getFilePathsForOutput($outputRelative . '/filtered/variants.vcf'),
                    'vcfPASSOutputFile'   => $this->getFilePathsForOutput(
                        $outputRelative . '/pass_filtered/variants.vcf'
                    ),
                    'textOutputFiles'     => $this->getFilePathsForOutput($outputRelative . '/output/intermediate.zip'),
                    'reportOutputFile'    => $this->getFilePathsForOutput($outputRelative . '/output/report.html'),
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
        if ($this->validateFileParameter('vcf')) {
            return true;
        }
        if ($this->validateFileParameter('tumor.bam') && $this->validateFileParameter('normal.bam')) {
            return true;
        }
        if ($this->validateFileParameter('tumor.ubam') && $this->validateFileParameter('normal.ubam')) {
            return true;
        }
        if ($this->validateFileParameter('tumor.fastq1') && $this->validateFileParameter('normal.fastq1')) {
            if (!$paired) {
                return true;
            }
            if ($this->validateFileParameter('tumor.fastq2') && $this->validateFileParameter('normal.fastq2')) {
                return true;
            }
        }

        return false;
    }
}
