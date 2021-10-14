<?php
/**
 * Oncoreport Web Service
 *
 * @author S. Alaimo, Ph.D. <alaimos at gmail dot com>
 */

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\Patient\Drug\StorePatientDrugRequest;
use App\Http\Requests\Api\Patient\Drug\UpdatePatientDrugRequest;
use App\Http\Resources\PatientDrugResource;
use App\Http\Services\BuilderRequestService;
use App\Http\Services\PatientHelperService;
use App\Models\Patient;
use App\Models\PatientDrug;
use F9Web\ApiResponseHelpers;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;

class PatientDrugController extends Controller
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

        return PatientDrugResource::collection(
            $requestService->handle($request, $patient->drugs())
        );
    }

    /**
     * Store a newly created resource in storage.
     *
     * @param  \App\Http\Requests\Api\Patient\Drug\StorePatientDrugRequest  $request
     * @param  \App\Models\Patient  $patient
     * @param  \App\Http\Services\PatientHelperService  $helperService
     *
     * @return \App\Http\Resources\PatientDrugResource
     * @throws \Illuminate\Auth\Access\AuthorizationException
     */
    public function store(
        StorePatientDrugRequest $request,
        Patient $patient,
        PatientHelperService $helperService
    ): PatientDrugResource {
        $this->tokenAuthorize($request, ['read', 'create'], 'update', $patient);

        return new PatientDrugResource(
            $helperService->createOrUpdateDrug($patient, $request->validated())
        );
    }

    /**
     * Display the specified resource.
     *
     * @param  \Illuminate\Http\Request  $request
     * @param  \App\Models\Patient  $patient
     * @param  \App\Models\PatientDrug  $drug
     *
     * @return \App\Http\Resources\PatientDrugResource
     * @throws \Illuminate\Auth\Access\AuthorizationException
     */
    public function show(Request $request, Patient $patient, PatientDrug $drug): PatientDrugResource
    {
        $this->tokenAuthorize($request, 'read', 'view', $patient);

        return new PatientDrugResource($drug);
    }

    /**
     * Update the specified resource in storage.
     *
     * @param  \App\Http\Requests\Api\Patient\Drug\UpdatePatientDrugRequest  $request
     * @param  \App\Models\Patient  $patient
     * @param  \App\Models\PatientDrug  $drug
     * @param  \App\Http\Services\PatientHelperService  $helperService
     *
     * @return \App\Http\Resources\PatientDrugResource
     * @throws \Illuminate\Auth\Access\AuthorizationException
     */
    public function update(
        UpdatePatientDrugRequest $request,
        Patient $patient,
        PatientDrug $drug,
        PatientHelperService $helperService
    ): PatientDrugResource {
        $this->tokenAuthorize($request, ['read', 'update'], 'update', $patient);

        return new PatientDrugResource(
            $helperService->createOrUpdateDrug(
                $patient,
                ['id' => $drug->id] + $request->validated()
            )
        );
    }

    /**
     * Remove the specified resource from storage.
     *
     * @param  \Illuminate\Http\Request  $request
     * @param  \App\Models\Patient  $patient
     * @param  \App\Models\PatientDrug  $drug
     *
     * @return \Illuminate\Http\JsonResponse
     * @throws \Illuminate\Auth\Access\AuthorizationException
     */
    public function destroy(Request $request, Patient $patient, PatientDrug $drug): JsonResponse
    {
        $this->tokenAuthorize($request, ['read', 'update', 'delete'], 'view', $patient);
        $drug->delete();

        return $this->respondNoContent();
    }


}
