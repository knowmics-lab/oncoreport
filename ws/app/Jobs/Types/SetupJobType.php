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
use Exception;
use Illuminate\Http\Request;

class SetupJobType extends AbstractJob
{

    use UsesCommandLine;

    /**
     * Returns an array containing for each input parameter a help to detail its content and use.
     *
     * @return array
     */
    public static function parametersSpec(): array
    {
        return [
            'cosmic_username' => 'The cosmic username',
            'cosmic_password' => 'The cosmic password',
        ];
    }

    /**
     * Returns an array containing for each output value an help detailing its use.
     *
     * @return array
     */
    public static function outputSpec(): array
    {
        return [];
    }

    /**
     * Returns a description for this job
     *
     * @return string
     */
    public static function description(): string
    {
        return 'Runs the setup script';
    }

    /**
     * @inheritDoc
     */
    public static function displayName(): string
    {
        return 'Setup Job';
    }

    /**
     * @inheritDoc
     */
    public static function validationSpec(Request $request): array
    {
        return [
            'cosmic_username' => ['filled', 'string'],
            'cosmic_password' => ['filled', 'string'],
        ];
    }

    /**
     * @inheritDoc
     */
    public static function patientInputState(): string
    {
        return self::NO_PATIENT;
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
        $setupDoneFile = storage_path('app/cosmic/.setup_done');
        if (file_exists($setupDoneFile)) {
            throw new ProcessingJobException('Setup already done!');
        }
        try {
            $this->log('Starting setup...');
            $this->initCommand(
                'bash',
                self::scriptPath('setup.bash'),
                '-u',
                $this->getParameter('cosmic_username'),
                '-p',
                $this->getParameter('cosmic_password'),
            );
            $model = $this->model;
            try {
                self::runCommand(
                    command:      $this->command(),
                    cwd:          $this->getAbsoluteJobDirectory(),
                    callback: static function ($type, $buffer) use ($model) {
                        $model->appendLog($buffer, false);
                    },
                    env:          true,
                    errorCodeMap: [
                                      101 => 'Invalid Parameter',
                                      102 => 'COSMIC username is required',
                                      103 => 'COSMIC password is required',
                                      104 => 'Unable to prepare indexes',
                                      105 => 'Unable to download cosmic database',
                                      106 => 'Setup already done',
                                  ]
                );
            } catch (IgnoredException $e) {
                $this->log("\n\nUnable to complete the setup procedure! Try again!");
                throw $e;
            }
            $this->log('Setup completed successfully!');
            @touch($setupDoneFile);
            @chmod($setupDoneFile, 0777);
        } catch (Exception $e) {
            throw_if($e instanceof ProcessingJobException, $e);
            throw_if($e instanceof IgnoredException, $e);
            throw new ProcessingJobException('An error occurred during job processing.', 0, $e);
        }
    }

}
