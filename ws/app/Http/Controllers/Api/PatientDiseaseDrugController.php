<?php
/**
 * Oncoreport Web Service
 *
 * @author S. Alaimo, Ph.D. <alaimos at gmail dot com>
 */

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\Patient\Disease\Drug\StorePatientDiseaseDrugRequest;
use App\Http\Requests\Api\Patient\Disease\Drug\UpdatePatientDiseaseDrugRequest;
use App\Http\Resources\PatientDrugResource;
use App\Http\Services\BuilderRequestService;
use App\Http\Services\PatientHelperService;
use App\Models\Patient;
use App\Models\PatientDisease;
use App\Models\PatientDrug;
use F9Web\ApiResponseHelpers;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;

class PatientDiseaseDrugController extends Controller
{
    use ApiResponseHelpers;

    /**
     * Display a listing of the resource.
     *
     * @param  \Illuminate\Http\Request  $request
     * @param  \App\Models\Patient  $patient
     * @param  \App\Models\PatientDisease  $disease
     * @param  \App\Http\Services\BuilderRequestService  $requestService
     *
     * @return \Illuminate\Http\Resources\Json\AnonymousResourceCollection
     * @throws \Illuminate\Auth\Access\AuthorizationException
     */
    public function index(
        Request $request,
        Patient $patient,
        PatientDisease $disease,
        BuilderRequestService $requestService
    ): AnonymousResourceCollection {
        $this->tokenAuthorize($request, ['read', 'update'], 'view', $patient);

        return PatientDrugResource::collection(
            $requestService->handle(
                $request,
                $patient->drugs()->whereNotNull('patient_disease_id')->where(
                    'patient_disease_id',
                    $disease->id
                )->getQuery()
            )
        );
    }

    /**
     * Store a newly created resource in storage.
     *
     * @param  \App\Http\Requests\Api\Patient\Disease\Drug\StorePatientDiseaseDrugRequest  $request
     * @param  \App\Models\Patient  $patient
     * @param  \App\Models\PatientDisease  $disease
     * @param  \App\Http\Services\PatientHelperService  $helperService
     *
     * @return \App\Http\Resources\PatientDrugResource
     * @throws \Illuminate\Auth\Access\AuthorizationException
     */
    public function store(
        StorePatientDiseaseDrugRequest $request,
        Patient $patient,
        PatientDisease $disease,
        PatientHelperService $helperService
    ): PatientDrugResource {
        $this->tokenAuthorize($request, ['read', 'create'], 'update', $patient);

        return new PatientDrugResource(
            $helperService->createOrUpdateDrug(
                $patient,
                ['disease' => $disease->id] + $request->validated()
            )
        );
    }

    /**
     * Display the specified resource.
     *
     * @param  \Illuminate\Http\Request  $request
     * @param  \App\Models\Patient  $patient
     * @param  \App\Models\PatientDisease  $disease
     * @param  \App\Models\PatientDrug  $drug
     *
     * @return \App\Http\Resources\PatientDrugResource
     * @throws \Illuminate\Auth\Access\AuthorizationException
     */
    public function show(
        Request $request,
        Patient $patient,
        PatientDisease $disease,
        PatientDrug $drug
    ): PatientDrugResource {
        $this->tokenAuthorize($request, 'read', 'view', $patient);
        abort_if($patient->id !== $drug->patient_id, 404);
        abort_if($disease->id !== $drug->patient_disease_id, 404);

        return new PatientDrugResource($drug);
    }

    /**
     * Update the specified resource in storage.
     *
     * @param  \App\Http\Requests\Api\Patient\Disease\Drug\UpdatePatientDiseaseDrugRequest  $request
     * @param  \App\Models\Patient  $patient
     * @param  \App\Models\PatientDisease  $disease
     * @param  \App\Models\PatientDrug  $drug
     * @param  \App\Http\Services\PatientHelperService  $helperService
     *
     * @return \App\Http\Resources\PatientDrugResource
     * @throws \Illuminate\Auth\Access\AuthorizationException
     */
    public function update(
        UpdatePatientDiseaseDrugRequest $request,
        Patient $patient,
        PatientDisease $disease,
        PatientDrug $drug,
        PatientHelperService $helperService
    ): PatientDrugResource {
        $this->tokenAuthorize($request, ['read', 'update'], 'update', $patient);
        abort_if($patient->id !== $drug->patient_id, 404);
        abort_if($disease->id !== $drug->patient_disease_id, 404);

        return new PatientDrugResource(
            $helperService->createOrUpdateDrug(
                $patient,
                ['id' => $drug->id, 'disease' => $disease->id] + $request->validated()
            )
        );
    }

    /**
     * Remove the specified resource from storage.
     *
     * @param  \Illuminate\Http\Request  $request
     * @param  \App\Models\Patient  $patient
     * @param  \App\Models\PatientDisease  $disease
     * @param  \App\Models\PatientDrug  $drug
     *
     * @return \Illuminate\Http\JsonResponse
     * @throws \Illuminate\Auth\Access\AuthorizationException
     */
    public function destroy(
        Request $request,
        Patient $patient,
        PatientDisease $disease,
        PatientDrug $drug
    ): JsonResponse {
        $this->tokenAuthorize($request, ['read', 'update', 'delete'], 'view', $patient);
        abort_if($patient->id !== $drug->patient_id, 404);
        abort_if($disease->id !== $drug->patient_disease_id, 404);
        $drug->delete();

        return $this->respondNoContent();
    }


}
