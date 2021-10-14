<?php
/**
 * Oncoreport Web Service
 *
 * @author S. Alaimo, Ph.D. <alaimos at gmail dot com>
 */

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\Patient\Disease\StorePatientDiseaseRequest;
use App\Http\Requests\Api\Patient\Disease\UpdatePatientDiseaseRequest;
use App\Http\Resources\PatientDiseaseResource;
use App\Http\Services\BuilderRequestService;
use App\Http\Services\PatientHelperService;
use App\Models\Patient;
use App\Models\PatientDisease;
use F9Web\ApiResponseHelpers;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;

class PatientDiseaseController extends Controller
{
    use ApiResponseHelpers;

    /**
     * Display a listing of the resource.
     *
     * @param  \Illuminate\Http\Request  $request
     * @param  \App\Models\Patient  $patient
     * @param  \App\Http\Services\BuilderRequestService  $requestService
     *
     * @return \Illuminate\Http\Resources\Json\AnonymousResourceCollection
     * @throws \Illuminate\Auth\Access\AuthorizationException
     */
    public function index(
        Request $request,
        Patient $patient,
        BuilderRequestService $requestService
    ): AnonymousResourceCollection {
        $this->tokenAuthorize($request, ['read', 'update'], 'view', $patient);

        return PatientDiseaseResource::collection(
            $requestService->handle($request, $patient->diseases())
        );
    }

    /**
     * Store a newly created resource in storage.
     *
     * @param  \App\Http\Requests\Api\Patient\Disease\StorePatientDiseaseRequest  $request
     * @param  \App\Models\Patient  $patient
     * @param  \App\Http\Services\PatientHelperService  $helperService
     *
     * @return \App\Http\Resources\PatientDiseaseResource
     * @throws \Illuminate\Auth\Access\AuthorizationException
     */
    public function store(
        StorePatientDiseaseRequest $request,
        Patient $patient,
        PatientHelperService $helperService
    ): PatientDiseaseResource {
        $this->tokenAuthorize($request, ['read', 'create'], 'update', $patient);

        return new PatientDiseaseResource(
            $helperService->createOrUpdateDisease($patient, $request->validated())
        );
    }

    /**
     * Display the specified resource.
     *
     * @param  \Illuminate\Http\Request  $request
     * @param  \App\Models\Patient  $patient
     * @param  \App\Models\PatientDisease  $disease
     *
     * @return \App\Http\Resources\PatientDiseaseResource
     * @throws \Illuminate\Auth\Access\AuthorizationException
     */
    public function show(Request $request, Patient $patient, PatientDisease $disease): PatientDiseaseResource
    {
        $this->tokenAuthorize($request, 'read', 'view', $patient);

        return new PatientDiseaseResource($disease);
    }

    /**
     * Update the specified resource in storage.
     *
     * @param  \App\Http\Requests\Api\Patient\Disease\UpdatePatientDiseaseRequest  $request
     * @param  \App\Models\Patient  $patient
     * @param  \App\Models\PatientDisease  $disease
     * @param  \App\Http\Services\PatientHelperService  $helperService
     *
     * @return \App\Http\Resources\PatientDiseaseResource
     * @throws \Illuminate\Auth\Access\AuthorizationException
     */
    public function update(
        UpdatePatientDiseaseRequest $request,
        Patient $patient,
        PatientDisease $disease,
        PatientHelperService $helperService
    ): PatientDiseaseResource {
        $this->tokenAuthorize($request, ['read', 'update'], 'update', $patient);

        return new PatientDiseaseResource(
            $helperService->createOrUpdateDisease(
                $patient,
                ['id' => $disease->id] + $request->validated()
            )
        );
    }

    /**
     * Remove the specified resource from storage.
     *
     * @param  \Illuminate\Http\Request  $request
     * @param  \App\Models\Patient  $patient
     * @param  \App\Models\PatientDisease  $disease
     *
     * @return \Illuminate\Http\JsonResponse
     * @throws \Illuminate\Auth\Access\AuthorizationException
     */
    public function destroy(Request $request, Patient $patient, PatientDisease $disease): JsonResponse
    {
        $this->tokenAuthorize($request, ['read', 'update', 'delete'], 'view', $patient);
        $disease->delete();

        return $this->respondNoContent();
    }


}
