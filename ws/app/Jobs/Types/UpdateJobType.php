<?php
/**
 * Oncoreport Web Service
 *
 * @author S. Alaimo, Ph.D. <alaimos at gmail dot com>
 */

namespace App\Jobs\Types;

use App\Exceptions\IgnoredException;
use App\Exceptions\ProcessingJobException;
use App\Http\Services\SystemInfoService;
use App\Jobs\Traits\UsesCommandLine;
use App\Models\Job;
use Exception;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Artisan;
use Symfony\Component\Console\Output\Output;

class UpdateJobType extends AbstractJob
{

    use UsesCommandLine;

    /**
     * Returns an array containing for each input parameter a help to detail its content and use.
     *
     * @return array
     */
    public static function parametersSpec(): array
    {
        return [];
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
        return 'Runs the update script';
    }

    /**
     * @inheritDoc
     */
    public static function displayName(): string
    {
        return 'Update Job';
    }

    /**
     * @inheritDoc
     */
    public static function validationSpec(Request $request): array
    {
        return [];
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
        $isUpdateNeeded = (new SystemInfoService())->isUpdateNeeded();
        if (!$isUpdateNeeded) {
            throw new ProcessingJobException('Update is not needed!');
        }
        try {
            $this->log('Starting update...');
            $model = $this->model;
            $outputBuffer = new class($model) extends Output {

                public function __construct(private Job $model)
                {
                    parent::__construct();
                }

                protected function doWrite(string $message, bool $newline): void
                {
                    $this->model->appendLog($message, $newline);
                }
            };
            $exitCode = Artisan::call('update:run', outputBuffer: $outputBuffer);
            if ($exitCode !== 0) {
                throw new ProcessingJobException('An error occurred during update!');
            }
            $this->log('Setup completed successfully!');
        } catch (Exception $e) {
            throw_if($e instanceof ProcessingJobException, $e);
            throw_if($e instanceof IgnoredException, $e);
            throw new ProcessingJobException('An error occurred during job processing.', 0, $e);
        }
    }

}
