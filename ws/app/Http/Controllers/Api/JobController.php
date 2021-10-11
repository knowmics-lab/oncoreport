<?php
/**
 * Oncoreport Web Service
 *
 * @author S. Alaimo, Ph.D. <alaimos at gmail dot com>
 */

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\JobResource;
use App\Http\Services\JobsCollectionService;
use App\Jobs\Request as JobRequest;
use App\Jobs\Types\AbstractJob;
use App\Jobs\Types\Factory;
use App\Models\Job;
use App\Models\Patient;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Support\Arr;
use Illuminate\Support\Str;
use Illuminate\Validation\Rule;

class JobController extends Controller
{

    /**
     * Display a listing of the resource.
     *
     * @param  \Illuminate\Http\Request  $request
     * @param  \App\Http\Services\JobsCollectionService  $collectionService
     *
     * @return \Illuminate\Http\Resources\Json\AnonymousResourceCollection
     * @throws \Illuminate\Auth\Access\AuthorizationException
     */
    public function index(Request $request, JobsCollectionService $collectionService): AnonymousResourceCollection
    {
        $this->tokenAuthorize($request, 'read', 'viewAny', Job::class);
        if ($request->has('patient') && ($id = (int)$request->input('patient'))) {
            $this->authorize('view', Patient::findOrFail($id));
        }

        return $collectionService->build($request, Job::byUser($request->user()));
    }

    /**
     * Store a newly created resource in storage.
     *
     * @param  \Illuminate\Http\Request  $request
     *
     * @return \App\Http\Resources\JobResource
     * @throws \Illuminate\Validation\ValidationException
     * @throws \Illuminate\Auth\Access\AuthorizationException
     */
    public function store(Request $request): JobResource
    {
        $this->authorize('create', Job::class);
        abort_unless($request->user()->tokenCan('read'), 403, 'User token is not allowed to read objects');
        abort_unless($request->user()->tokenCan('create'), 403, 'User token is not allowed to create objects');
        $jobTypes = Factory::listTypes();
        $validValues = $this->validate(
            $request,
            [
                'sample_code' => ['required', 'string', 'alpha_dash'],
                'name'        => ['required', 'string'],
                'type'        => ['required', 'string', Rule::in($jobTypes->pluck('id'))],
                'parameters'  => ['filled', 'array'],
            ]
        );
        $parametersValidation = $this->prepareNestedValidation(Factory::validationSpec($validValues['type'], $request));
        $patientInputState = Factory::patientInputState($validValues['type']);
        $patientInputValidation = ['integer', Rule::exists('patients', 'id')];
        $noPatientInput = $patientInputState === AbstractJob::NO_PATIENT;
        if ($patientInputState === AbstractJob::PATIENT_REQUIRED) {
            $parametersValidation['patient_id'] = ['required', ...$patientInputValidation];
        } elseif ($patientInputState === AbstractJob::PATIENT_OPTIONAL) {
            $parametersValidation['patient_id'] = ['filled', ...$patientInputValidation];
        }
        $validParameters = $this->validate($request, $parametersValidation);
        $type = $validValues['type'];
        $patientId = $noPatientInput ? null : ($validParameters['patient_id'] ?? null);
        $validParameters = $validParameters['parameters'] ?? [];
        $job = Job::create(
            [
                'sample_code' => $validValues['sample_code'],
                'name' => $validValues['name'],
                'job_type' => $type,
                'status' => Job::READY,
                'job_parameters' => [],
                'job_output' => [],
                'log' => '',
                'patient_id' => $patientId,
                'user_id' => $request->user()->id,
            ]
        );
        $job->setParameters(Arr::dot($validParameters));
        $job->save();
        $job->getJobDirectory();

        return new JobResource($job);
    }

    /**
     * Prepare array for nested validation
     *
     * @param  array  $specs
     *
     * @return array
     */
    private function prepareNestedValidation(array $specs): array
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

    /**
     * Display the specified resource.
     *
     * @param  \Illuminate\Http\Request  $request
     * @param  \App\Models\Job  $job
     *
     * @return \App\Http\Resources\JobResource
     * @throws \Illuminate\Auth\Access\AuthorizationException
     */
    public function show(Request $request, Job $job): JobResource
    {
        $this->authorize('view', $job);
        abort_unless($request->user()->tokenCan('read'), 403, 'User token is not allowed to read objects');

        return new JobResource($job);
    }

    /**
     * Update the specified resource in storage.
     *
     * @param  \Illuminate\Http\Request  $request
     * @param  \App\Models\Job  $job
     *
     * @return \App\Http\Resources\JobResource
     * @throws \Illuminate\Validation\ValidationException
     * @throws \Illuminate\Auth\Access\AuthorizationException
     */
    public function update(Request $request, Job $job): JobResource
    {
        $this->authorize('update', $job);
        abort_unless($request->user()->tokenCan('read'), 403, 'User token is not allowed to read objects');
        abort_unless($request->user()->tokenCan('update'), 403, 'User token is not allowed to update objects');
        abort_unless($job->canBeModified(), 400, 'Unable to modify a queued or running job.');
        $validValues = $this->validate(
            $request,
            [
                'sample_code' => ['filled', 'string', 'alpha_dash'],
                'name'        => ['filled', 'string'],
                'parameters'  => ['filled', 'array'],
                'patient_id'  => ['nullable', 'integer', Rule::exists('patients', 'id')],
            ]
        );
        $patientInputState = Factory::patientInputState($job->job_type);
        $noPatientInput = $patientInputState === AbstractJob::NO_PATIENT;
        if ($noPatientInput) {
            $patientId = null;
        } elseif (array_key_exists('patient_id', $validValues)) {
            $patientId = $validValues['patient_id'];
        } else {
            $patientId = $job->patient_id;
        }
        $parametersValidation = $this->prepareNestedValidation(Factory::validationSpec($job, $request));
        $validParameters = $this->validate($request, $parametersValidation);
        $validParameters = $validParameters['parameters'] ?? [];
        $job->fill(
            [
                'sample_code' => $validValues['sample_code'] ?? $job->sample_code,
                'name'        => $validValues['name'] ?? $job->name,
                'patient_id'  => $patientId,
            ]
        );
        $job->addParameters(Arr::dot($validParameters));
        $job->save();

        return new JobResource($job);
    }

    /**
     * Remove the specified resource from storage.
     *
     * @param  \Illuminate\Http\Request  $request
     * @param  \App\Models\Job  $job
     *
     * @return \Illuminate\Http\JsonResponse
     * @throws \Illuminate\Auth\Access\AuthorizationException
     */
    public function destroy(Request $request, Job $job): JsonResponse
    {
        $this->authorize('delete', $job);
        abort_unless($request->user()->tokenCan('read'), 403, 'User token is not allowed to read objects');
        abort_unless($request->user()->tokenCan('delete'), 403, 'User token is not allowed to delete objects');
        abort_unless($job->canBeDeleted(), 400, 'Unable to delete a queued or running job.');

        try {
            $job->deleteJobDirectory();
            $job->delete();
        } catch (\Throwable $e) {
            return response()->json(
                [
                    'message' => $e->getMessage(),
                    'errors'  => true,
                ]
            );
        }

        return response()->json(
            [
                'message' => 'Patient deleted.',
                'errors'  => false,
            ]
        );
    }

    /**
     * Submit the specified resource for execution
     *
     * @param  \Illuminate\Http\Request  $request
     * @param  \App\Models\Job  $job
     *
     * @return \App\Http\Resources\JobResource
     * @throws \Illuminate\Auth\Access\AuthorizationException
     */
    public function submit(Request $request, Job $job): JobResource
    {
        $this->authorize('submitJob', $job);
        abort_unless($request->user()->tokenCan('read'), 403, 'User token is not allowed to read objects');
        abort_unless($request->user()->tokenCan('update'), 403, 'User token is not allowed to update objects');
        abort_unless($job->canBeModified(), 400, 'Unable to submit a job that is already submitted.');
        $job->setStatus(Job::QUEUED);
        JobRequest::dispatch($job);

        return new JobResource($job);
    }

    /**
     * Upload a file to the specified job
     *
     * @param  \Illuminate\Http\Request  $request
     * @param  \App\Models\Job  $job
     *
     * @return mixed
     * @throws \Illuminate\Auth\Access\AuthorizationException
     */
    public function upload(Request $request, Job $job)
    {
        $this->authorize('uploadJob', $job);
        abort_unless($request->user()->tokenCan('read'), 403, 'User token is not allowed to read objects');
        abort_unless($request->user()->tokenCan('create'), 403, 'User token is not allowed to create objects');
        abort_unless($job->canBeModified(), 400, 'Unable to upload a file for a job that is already submitted.');
        set_time_limit(0);
        /** @var \TusPhp\Tus\Server $server */
        $server = app('tus-server');
        $server->setApiPath(route('jobs.upload', $job, false))
               ->setUploadDir($job->getAbsoluteJobDirectory());
        $response = $server->serve();

        return $response->send();
    }
}
