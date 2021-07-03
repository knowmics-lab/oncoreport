<?php
/**
 * Oncoreport Web Service
 *
 * @author S. Alaimo, Ph.D. <alaimos at gmail dot com>
 */

namespace App\Jobs\Types;

use App\Exceptions\ProcessingJobException;
use Auth;
use Exception;
use Illuminate\Http\Request;

class TestJobType extends AbstractJob
{

    /**
     * Returns an array containing for each input parameter an help detailing its content and use.
     *
     * @return array
     */
    public static function parametersSpec(): array
    {
        return [
            'name' => 'A string containing a name',
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
            'greetings' => 'A greeting to the user',
        ];
    }

    /**
     * Handles all the computation for this job.
     * This function should throw a ProcessingJobException if something went wrong during the computation.
     * If no exceptions are thrown the job is considered as successfully completed.
     *
     * @throws \App\Exceptions\ProcessingJobException
     */
    public function handle(): void
    {
        try {
            $this->log('Starting the test job!');
            if ($this->model->patient_id !== null) {
                $this->log('This job is tied to the patient "' . $this->model->patient->full_name . '".');
            }
            $name = $this->model->getParameter('name', Auth::user()->name);
            $this->model->setOutput('greetings', 'Hello ' . $name . '!!');
            $this->log('Test job ended');
        } catch (Exception $e) {
            throw new ProcessingJobException('An error occurred during job processing.', 0, $e);
        }
    }

    /**
     * Returns a description for this job
     *
     * @return string
     */
    public static function description(): string
    {
        return 'A greeting to the user';
    }

    public static function displayName(): string
    {
        return 'Test Job Type';
    }

    public static function validationSpec(Request $request): array
    {
        return [
            'name' => ['filled', 'string'],
        ];
    }

    public static function patientInputState(): string
    {
        return self::PATIENT_OPTIONAL;
    }
}
