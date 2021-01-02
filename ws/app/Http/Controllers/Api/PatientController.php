<?php
/**
 * Oncoreport Web Service
 *
 * @author S. Alaimo, Ph.D. <alaimos at gmail dot com>
 */

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\Patient as PatientResource;
use App\Http\Resources\PatientCollection;
use App\Models\Disease;
use App\Models\Patient;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class PatientController extends Controller
{

    /**
     * Display a listing of the resource.
     *
     * @param \Illuminate\Http\Request $request
     *
     * @return \App\Http\Resources\PatientCollection
     * @throws \Illuminate\Auth\Access\AuthorizationException
     */
    public function index(Request $request): PatientCollection
    {
        $this->authorize('viewAny', Patient::class);
        abort_unless($request->user()->tokenCan('read'), 403, 'User token is not allowed to read objects');

        return new PatientCollection($this->handleBuilderRequest($request, Patient::with('disease')));
    }

    /**
     * Store a newly created resource in storage.
     *
     * @param \Illuminate\Http\Request $request
     *
     * @return \App\Http\Resources\Patient
     * @throws \Illuminate\Validation\ValidationException
     * @throws \Illuminate\Auth\Access\AuthorizationException
     */
    public function store(Request $request): PatientResource
    {
        $this->authorize('create', Patient::class);
        abort_unless($request->user()->tokenCan('read'), 403, 'User token is not allowed to read objects');
        abort_unless($request->user()->tokenCan('create'), 403, 'User token is not allowed to create objects');
        $values = $this->validate(
            $request,
            [
                'code'       => ['required', 'string', 'alpha_dash', 'max:255'],
                'first_name' => ['required', 'string', 'max:255'],
                'last_name'  => ['required', 'string', 'max:255'],
                'gender'     => ['required', 'string', Rule::in(Patient::VALID_GENDERS)],
                'age'        => ['required', 'integer', 'between:0,100'],
                'disease_id' => ['required_without:disease', 'integer', 'exists:diseases,id'],
                'disease'    => ['required_without:disease_id', 'string', 'exists:diseases,name'],
            ]
        );
        $model = Patient::create(
            [
                'code'       => $values['code'],
                'first_name' => $values['first_name'],
                'last_name'  => $values['last_name'],
                'gender'     => $values['gender'],
                'age'        => $values['age'],
                'disease_id' => $values['disease_id'] ?? Disease::whereName($values['disease'])->firstOrFail()->id,
                'user_id'    => $request->user()->id,
            ]
        );
        $model->save();

        return new PatientResource($model);
    }

    /**
     * Display the specified resource.
     *
     * @param \Illuminate\Http\Request $request
     * @param \App\Models\Patient      $patient
     *
     * @return \App\Http\Resources\Patient
     * @throws \Illuminate\Auth\Access\AuthorizationException
     */
    public function show(Request $request, Patient $patient): PatientResource
    {
        $this->authorize('view', $patient);
        abort_unless($request->user()->tokenCan('read'), 403, 'User token is not allowed to read objects');

        return new PatientResource($patient);
    }

    /**
     * Update the specified resource in storage.
     *
     * @param \Illuminate\Http\Request $request
     * @param \App\Models\Patient      $patient
     *
     * @return \App\Http\Resources\Patient
     * @throws \Illuminate\Validation\ValidationException
     * @throws \Illuminate\Auth\Access\AuthorizationException
     */
    public function update(Request $request, Patient $patient): PatientResource
    {
        $this->authorize('update', $patient);
        abort_unless($request->user()->tokenCan('read'), 403, 'User token is not allowed to read objects');
        abort_unless($request->user()->tokenCan('update'), 403, 'User token is not allowed to update objects');
        $rules = [
            'code'       => ['filled', 'string', 'alpha_dash', 'max:255'],
            'first_name' => ['filled', 'string', 'max:255'],
            'last_name'  => ['filled', 'string', 'max:255'],
            'gender'     => ['filled', 'string', Rule::in(Patient::VALID_GENDERS)],
            'age'        => ['filled', 'integer'],
            'disease_id' => ['filled', 'integer', 'exists:diseases,id'],
            'disease'    => ['filled', 'string', 'exists:diseases,name'],
        ];
        $values = $this->validate($request, $rules);
        $disease_id = $values['disease_id'] ?? (
            isset($values['disease']) ? Disease::whereName($values['disease'])->firstOrFail()->id : $patient->disease_id);
        $patient->forceFill(
            [
                "code"       => $values['code'] ?? $patient->code,
                "first_name" => $values['first_name'] ?? $patient->first_name,
                "last_name"  => $values['last_name'] ?? $patient->last_name,
                "gender"     => $values['gender'] ?? $patient->gender,
                "age"        => $values['age'] ?? $patient->age,
                "disease_id" => $disease_id,
            ]
        )->save();
        $patient->save();

        return new PatientResource($patient);
    }

    /**
     * Remove the specified resource from storage.
     *
     * @param \Illuminate\Http\Request $request
     * @param \App\Models\Patient      $patient
     *
     * @return \Illuminate\Http\JsonResponse
     * @throws \Exception
     */
    public function destroy(Request $request, Patient $patient): JsonResponse
    {
        $this->authorize('delete', $patient);
        abort_unless($request->user()->tokenCan('read'), 403, 'User token is not allowed to read objects');
        abort_unless($request->user()->tokenCan('delete'), 403, 'User token is not allowed to delete objects');
        $patient->delete();

        return response()->json(
            [
                'message' => 'Patient deleted.',
                'errors'  => false,
            ]
        );
    }

}
