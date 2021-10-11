<?php

namespace App\Http\Services;

use App\Constants;
use App\Http\Requests\Api\Job\StoreJobRequest;
use App\Http\Requests\Api\Job\UpdateJobRequest;
use App\Jobs\Types\AbstractJob;
use App\Jobs\Types\Factory;
use App\Models\Job;
use App\Models\Patient;
use Illuminate\Support\Arr;
use Illuminate\Support\Str;
use Illuminate\Validation\Rule;
use JetBrains\PhpStorm\Pure;

class JobHelperService
{

    /**
     * Prepare array for nested validation
     *
     * @param  array  $specs
     *
     * @return array
     */
    #[Pure] private function prepareNestedValidation(array $specs): array
    {
        $nestedSpecs = [];
        foreach ($specs as $field => $rules) {
            if (!Str::startsWith($field, 'parameters.')) {
                $field = 'parameters.' . $field;
            }
            $nestedSpecs[$field] = $rules;
        }

        return $nestedSpecs;
    }

    public function prepareSecondValidation(StoreJobRequest|UpdateJobRequest $request): array
    {
        $validValues = $request->validated();
        $parametersValidation = $this->prepareNestedValidation(Factory::validationSpec($validValues['type'], $request));
        $patientInputState = Factory::patientInputState($validValues['type']);
        $noPatientInput = $patientInputState === AbstractJob::NO_PATIENT;
        if ($request instanceof StoreJobRequest) {
            $patientInputValidation = ['integer', Rule::exists('patients', 'id')];
            if ($patientInputState === AbstractJob::PATIENT_REQUIRED) {
                $parametersValidation['patient_id'] = ['required', ...$patientInputValidation];
            } elseif ($patientInputState === AbstractJob::PATIENT_OPTIONAL) {
                $parametersValidation['patient_id'] = ['filled', ...$patientInputValidation];
            }
        }

        return [$noPatientInput, $parametersValidation];
    }

    public function storeJob(array $validValues, array $validParameters, ?Patient $patient, ?int $userId): Job
    {
        $validParameters = $validParameters['parameters'] ?? [];
        $job = Job::create(
            [
                'sample_code' => $validValues['sample_code'],
                'name' => $validValues['name'],
                'job_type' => $validValues['type'],
                'status' => Constants::READY,
                'job_parameters' => [],
                'job_output' => [],
                'log' => '',
                'patient_id' => optional($patient)->id,
                'owner_id' => optional($patient)->owner_id ?? $userId,
            ]
        );
        $job->setParameters(Arr::dot($validParameters));
        $job->save();
        $job->getJobDirectory();

        return $job;
    }

    public function updateJob(
        Job $job,
        array $validValues,
        array $validParameters,
        ?Patient $patient,
        ?int $userId
    ): void {
        $validParameters = $validParameters['parameters'] ?? [];
        $job->fill(
            [
                'sample_code' => $validValues['sample_code'] ?? $job->sample_code,
                'name'        => $validValues['name'] ?? $job->name,
                'patient_id'  => optional($patient)->id,
                'owner_id'    => optional($patient)->owner_id ?? $userId,
            ]
        )
            ->addParameters(Arr::dot($validParameters))
            ->save();
    }

}