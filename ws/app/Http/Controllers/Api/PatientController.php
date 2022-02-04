<?php
/**
 * Oncoreport Web Service
 *
 * @author S. Alaimo, Ph.D. <alaimos at gmail dot com>
 */

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\Patient\StorePatientRequest;
use App\Http\Requests\Api\Patient\UpdatePatientRequest;
use App\Http\Resources\PatientResource;
use App\Http\Services\BuilderRequestService;
use App\Http\Services\PatientHelperService;
use App\Models\Patient;
use F9Web\ApiResponseHelpers;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;

class PatientController extends Controller
{
    use ApiResponseHelpers;

    /**
     * Display a listing of the resource.
     *
     * @param  \Illuminate\Http\Request  $request
     * @param  \App\Http\Services\BuilderRequestService  $requestService
     *
     * @return \Illuminate\Http\Resources\Json\AnonymousResourceCollection
     * @throws \Illuminate\Auth\Access\AuthorizationException
     */
    public function index(Request $request, BuilderRequestService $requestService): AnonymousResourceCollection
    {
        $this->tokenAuthorize($request, 'read', 'viewAny', Patient::class);

        return PatientResource::collection(
            $requestService->handle($request, Patient::with(['primaryDisease']), searchableFields: [
                'code',
                'first_name',
                'last_name',
            ])
        );
    }

    /**
     * Store a newly created resource in storage.
     *
     * @param  \App\Http\Requests\Api\Patient\StorePatientRequest  $request
     * @param  \App\Http\Services\PatientHelperService  $helperService
     *
     * @return \App\Http\Resources\PatientResource
     * @throws \Illuminate\Auth\Access\AuthorizationException
     * @throws \Throwable
     */
    public function store(StorePatientRequest $request, PatientHelperService $helperService): PatientResource
    {
        $this->tokenAuthorize($request, ['read', 'create'], 'create', Patient::class);

        return new PatientResource(
            $helperService->createPatient($request->validated(), optional($request->user())->id)
                          ->loadRelationships()
        );
    }

    /**
     * Display the specified resource.
     *
     * @param  \Illuminate\Http\Request  $request
     * @param  \App\Models\Patient  $patient
     *
     * @return \App\Http\Resources\PatientResource
     * @throws \Illuminate\Auth\Access\AuthorizationException
     */
    public function show(Request $request, Patient $patient): PatientResource
    {
        $this->tokenAuthorize($request, 'read', 'view', $patient);

        return new PatientResource($patient->loadRelationships());
    }

    /**
     * Update the specified resource in storage.
     *
     * @param  \App\Http\Requests\Api\Patient\UpdatePatientRequest  $request
     * @param  \App\Models\Patient  $patient
     * @param  \App\Http\Services\PatientHelperService  $helperService
     *
     * @return \App\Http\Resources\PatientResource
     * @throws \Illuminate\Auth\Access\AuthorizationException
     * @throws \Throwable
     */
    public function update(
        UpdatePatientRequest $request,
        Patient $patient,
        PatientHelperService $helperService
    ): PatientResource {
        $this->tokenAuthorize($request, ['read', 'update'], 'update', $patient);

        return new PatientResource(
            $helperService->updatePatient($patient, $request->validated())
                          ->loadRelationships()
        );
    }

    /**
     * Remove the specified resource from storage.
     *
     * @param  \Illuminate\Http\Request  $request
     * @param  \App\Models\Patient  $patient
     *
     * @return \Illuminate\Http\JsonResponse
     * @throws \Exception
     */
    public function destroy(Request $request, Patient $patient): JsonResponse
    {
        $this->tokenAuthorize($request, ['read', 'delete'], 'delete', $patient);
        $patient->delete();

        return $this->respondNoContent();
    }


}
