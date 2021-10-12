<?php
/**
 * Oncoreport Web Service
 *
 * @author S. Alaimo, Ph.D. <alaimos at gmail dot com>
 */

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\Patient\StorePatientRequest;
use App\Http\Resources\PatientResource;
use App\Http\Services\BuilderRequestService;
use App\Http\Services\PatientHelperService;
use App\Models\Disease;
use App\Models\Patient;
use DateTime;
use F9Web\ApiResponseHelpers;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Validation\Rule;

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
            $requestService->handle($request, Patient::with(['primaryDisease']))
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
     */
    public function store(StorePatientRequest $request, PatientHelperService $helperService): PatientResource
    {
        $this->tokenAuthorize($request, ['read', 'create'], 'create', Patient::class);

        return new PatientResource(
            $helperService->createPatient($request->validated(), optional($request->user())->id)
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
        $patient->load(['primaryDisease', 'diseases', 'drugs']);

        return new PatientResource($patient);
    }

    /**
     * Update the specified resource in storage.
     *
     * @param  \Illuminate\Http\Request  $request
     * @param  \App\Models\Patient  $patient
     *
     * @return \App\Http\Resources\PatientResource
     * @throws \Illuminate\Validation\ValidationException
     * @throws \Illuminate\Auth\Access\AuthorizationException
     */
    public function update(Request $request, Patient $patient): PatientResource
    {
        $data = $request->input();
        error_log(json_encode($data));

        $this->authorize('update', $patient);
        abort_unless($request->user()->tokenCan('read'), 403, 'User token is not allowed to read objects');
        abort_unless($request->user()->tokenCan('update'), 403, 'User token is not allowed to update objects');
        $rules = [
            'code'            => ['filled', 'string', 'alpha_dash', 'max:255'],
            'first_name'      => ['filled', 'string', 'max:255'],
            'last_name'       => ['filled', 'string', 'max:255'],
            'gender'          => ['filled', 'string', Rule::in(Patient::VALID_GENDERS)],
            'age'             => ['filled', 'integer'],
            'disease_id'      => ['filled', 'integer', 'exists:diseases,id'],
            'disease_site_id' => ['required'],
            'disease_stage'   => ['required'],
            'disease'         => ['filled', 'string', 'exists:diseases,name'],
            'email'           => ['required', 'email:rfc,dns'],
            'fiscalNumber'    => ['required', 'string'],
            'telephone'       => ['string', 'nullable'],
            'city'            => ['string', 'nullable'],
        ];
        $values = $this->validate($request, $rules);
        $disease_id = $values['disease_id'] ?? (
            isset($values['disease']) ? Disease::whereName($values['disease'])->firstOrFail(
            )->id : $patient->disease_id);
        $patient->forceFill(
            [
                "code"          => $values['code'] ?? $patient->code,
                "first_name"    => $values['first_name'] ?? $patient->first_name,
                "last_name"     => $values['last_name'] ?? $patient->last_name,
                "gender"        => $values['gender'] ?? $patient->gender,
                "age"           => $values['age'] ?? $patient->age,
                "disease_id"    => $disease_id,
                'T'             => $values['disease_stage']['T'],
                'M'             => $values['disease_stage']['M'],
                'N'             => $values['disease_stage']['N'],
                'location_id'   => $values['disease_site_id'],
                "fiscal_number" => $values['fiscalNUmber'] ?? $patient->fiscal_number,
                "email"         => $values['email'] ?? $patient->email,
                'telephone'     => $values['telephone'] ?? null,
                'city'          => $values['city'] ?? null,
            ]
        )->save();
        $patient->save();


        /** Update relationships */
        if ($request->input('diseases')) {
            $diseases = $request->input('diseases');
            $disease_ids = array_column($diseases, 'id');
            $patient->diseases()->sync($disease_ids);

            // Update medicines used to heal each disease
            foreach ($diseases as $disease) {
                $patient->diseases()->find($disease['id'])->pivot->medicines()->sync($disease['medicines']);
            }
        }


        if ($request->input('tumors')) {
            #error_log('log tumori');

            $tumors = $request->input('tumors');
            #error_log(json_encode($tumors));


            $tumor_ids = array_reduce($tumors, function ($carry, $tumor) {
                $carry[$tumor['id']] = [
                    'type' => $tumor['type'] ?? null,
                    //'sede' => $tumor['sede'],
                    'T'    => $tumor['stadio'] && $tumor['stadio'] != [] ? $tumor['stadio']['T'] ?? null : null,
                    'M'    => $tumor['stadio'] && $tumor['stadio'] != [] ? $tumor['stadio']['M'] ?? null : null,
                    'N'    => $tumor['stadio'] && $tumor['stadio'] != [] ? $tumor['stadio']['N'] ?? null : null,
                ];

                return $carry;
            });

            $patient->tumors()->sync($tumor_ids);


            foreach ($tumors as $tumor) {
                $drugs = $tumor['drugs'];

                $drug_ids = array_reduce($drugs, function ($_drugs, $drug) {
                    $_drugs[$drug['id']] = [
                        'start_date' => array_key_exists(
                            'start_date',
                            $drug
                        ) && $drug['start_date'] ? $drug['start_date'] : new DateTime('today'),
                        'end_date'   => array_key_exists('end_date', $drug) ? $drug['end_date'] : null,
                    ];

                    return $_drugs;
                });


                $patient->tumors()->find($tumor['id'])->pivot->drugs()->sync($drug_ids);
                #error_log('droghe aggiornate');

                if ($tumor['sede']) {
                    $location_ids = $tumor['sede'];
                    #error_log('aggiorniamo la sede di ' . $tumor['id'] .' con ' . json_encode($location_ids));
                    $patient->tumors()->find($tumor['id'])->pivot->locations()->sync($location_ids);
                }
                /* //Todo: aggiornare anche le ragioni. da testare.
                    foreach($drugs as $drug){
                        $reason_ids = array_column($drug['reasons'] ?? [], 'id');
                        $patient->tumors()->find($tumor['id'])->pivot->drugs()->find($drug['id'])->pivot->reasons()->sync($reason_ids);
                    }
                */
            }
        }


        return new PatientResource($patient);
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
