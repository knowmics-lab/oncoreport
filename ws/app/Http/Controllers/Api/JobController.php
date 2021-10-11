<?php
/**
 * Oncoreport Web Service
 *
 * @author S. Alaimo, Ph.D. <alaimos at gmail dot com>
 */

namespace App\Http\Controllers\Api;

use App\Constants;
use App\Http\Controllers\Controller;
use App\Http\Requests\Api\Job\StoreJobRequest;
use App\Http\Requests\Api\Job\UpdateJobRequest;
use App\Http\Resources\JobResource;
use App\Http\Services\JobHelperService;
use App\Http\Services\JobsCollectionService;
use App\Jobs\Request as JobRequest;
use App\Models\Job;
use App\Models\Patient;
use Error;
use F9Web\ApiResponseHelpers;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Throwable;

class JobController extends Controller
{
    use ApiResponseHelpers;

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
     * @param  \App\Http\Requests\Api\Job\StoreJobRequest  $request
     * @param  \App\Http\Services\JobHelperService  $helperService
     *
     * @return \Illuminate\Http\JsonResponse
     * @throws \Illuminate\Auth\Access\AuthorizationException
     */
    public function store(StoreJobRequest $request, JobHelperService $helperService): JsonResponse
    {
        $this->tokenAuthorize($request, ['read', 'create'], 'create', Job::class);
        $validValues = $request->validated();
        [$noPatientInput, $parametersValidation] = $helperService->prepareSecondValidation($request);
        $validParameters = $this->validate($request, $parametersValidation);
        $patient = $noPatientInput ? null : Patient::findOrFail($validParameters['patient_id']);
        if ($patient) {
            $this->authorize('view', $patient);
        }
        $job = $helperService->storeJob($validValues, $validParameters, $patient, optional($request->user())->id);

        return $this->respondCreated(new JobResource($job));
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
        $this->tokenAuthorize($request, 'read', 'view', $job);

        return new JobResource($job);
    }

    /**
     * Update the specified resource in storage.
     *
     * @param  \App\Http\Requests\Api\Job\UpdateJobRequest  $request
     * @param  \App\Models\Job  $job
     * @param  \App\Http\Services\JobHelperService  $helperService
     *
     * @return \App\Http\Resources\JobResource
     * @throws \Illuminate\Auth\Access\AuthorizationException
     */
    public function update(UpdateJobRequest $request, Job $job, JobHelperService $helperService): JobResource
    {
        $this->tokenAuthorize($request, ['read', 'update'], 'update', $job);
        abort_unless($job->canBeModified(), 400, 'Unable to modify a queued or running job.');
        $validValues = $request->validated();
        [$noPatientInput, $parametersValidation] = $helperService->prepareSecondValidation($request);
        if ($noPatientInput) {
            $patient = null;
        } elseif (array_key_exists('patient_id', $validValues)) {
            $patient = Patient::findOrFail($validValues['patient_id']);
        } else {
            $patient = $job->patient;
        }
        if ($patient) {
            $this->authorize('view', $patient);
        }
        $validParameters = $this->validate($request, $parametersValidation);
        $helperService->updateJob($job, $validValues, $validParameters, $patient, optional($request->user())->id);

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
        $this->tokenAuthorize($request, ['read', 'delete'], 'delete', $job);
        abort_unless($job->canBeDeleted(), 400, 'Unable to delete a queued or running job.');

        try {
            $job->deleteJobDirectory();
            $job->delete();
        } catch (Throwable | Error $e) {
            return $this->respondError($e->getMessage());
        }

        return $this->respondNoContent();
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
        $this->tokenAuthorize($request, ['read', 'update'], 'submitJob', $job);
        abort_unless($job->canBeModified(), 400, 'Unable to submit a job that is already submitted.');
        $job->setStatus(Constants::QUEUED);
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
    public function upload(Request $request, Job $job): mixed
    {
        $this->tokenAuthorize($request, ['read', 'update'], 'uploadJob', $job);
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
