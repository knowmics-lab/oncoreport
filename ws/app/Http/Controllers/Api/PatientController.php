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
use DateTime;
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
        $patient = Patient::create(
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
        $patient->save();

        if($request->input('diseases')){
            $diseases = $request->input('diseases');
            error_log(json_encode($diseases));


            $disease_ids = array_column($diseases, 'id');
            error_log(json_encode($disease_ids));


            $patient->diseases()->sync($disease_ids);
            foreach ($diseases as $disease) {
                error_log('salviamo la patologia '.$disease['id'].' con le medicine '.json_encode($disease['medicines']));
                $patient->diseases()->find($disease['id'])->pivot->medicines()->sync($disease['medicines']);
            }
        }


        /*
        if ($request->input('tumors')){
            $tumors = $request->input('tumors');

            $tumor_ids = array();
            $drugs_ids = array();
            foreach ($tumors as $tumor) {
                if($tumor['id']){
                    if(isset($tumor['stadio']))
                        $tumor_ids[$tumor['id']] = ['type' => $tumor['type'], 'T' => $tumor['stadio']['T'], 'M' => $tumor['stadio']['M'], 'N' => $tumor['stadio']['N']];
                    else
                        $tumor_ids[$tumor['id']] = ['type' => $tumor['type']];

                    if(array_key_exists('drugs',$tumor)){
                        $drug_ids = array();
                        foreach ($tumor['drugs'] as $drug) {
                            $drug_ids[$drug['id']] = [
                                'start_date' =>   array_key_exists('start_date', $drug) ? $drug['start_date'] : new DateTime('today'),
                                'end_date'   =>  array_key_exists('end_date', $drug) ? $drug['end_date'] : null
                            ];
                        }
                        $drugs_ids[$tumor['id']] = $drug_ids;
                    }
                }
            }

        }

        $patient->tumors()->sync($tumor_ids);

        foreach ($drugs_ids as $tumor_id => $drug_ids) {
            $patient->tumors()->find($tumor_id)->pivot->drugs()->sync($drug_ids);
        }
        */

        // Nuova gestione.
        if ($request->input('tumors')){
            error_log('log tumori');

            $tumors = $request->input('tumors');
            error_log(json_encode($tumors));

            //$tumor_ids = array_column($tumors, 'id');
            //error_log('salviamo questi tumori: ' . json_encode($tumor_ids));
            $tumor_ids = array();

            //$patient->tumors()->sync($tumor_ids);
            foreach ($tumors as $tumor){
                if($tumor['id']){
                    $tumor_ids[$tumor['id']] = [
                        'type' => $tumor['type'],
                        //'sede' => $tumor['sede'],
                        'T' => $tumor['stadio'] ? $tumor['stadio']['T'] : null,
                        'M' => $tumor['stadio'] ? $tumor['stadio']['M'] : null,
                        'N' => $tumor['stadio'] ? $tumor['stadio']['N'] : null,
                    ];
                }
            }

            error_log('aggiorniamo i tumori: ' . json_encode(array_keys($tumor_ids)));
            $patient->tumors()->sync($tumor_ids);
            error_log('tumori aggiornati');
            foreach ($tumors as $tumor) {
                $drugs = $tumor['drugs'];
                error_log('adesso forse aggiorniamo il tumore ' . $tumor['id'] . ' con le drugs ' . json_encode(array_column($drugs, 'id')));
                $drug_ids = array();

                foreach($drugs as $drug){
                    $drug_ids[$drug['id']] = [
                        'start_date' =>   array_key_exists('start_date', $drug) && $drug['start_date'] ? $drug['start_date'] : new DateTime('today'),
                        'end_date'   =>  array_key_exists('end_date', $drug) ? $drug['end_date'] : null
                    ];
                }
                error_log('aggiorniamo le droghe per ' . json_encode($tumor['id']) . ' con ' . json_encode($drug_ids));
                $patient->tumors()->find($tumor['id'])->pivot->drugs()->sync($drug_ids);

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
        error_log('ciao');
        $data = $request->input();
        error_log(json_encode($data));

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


        if($request->input('diseases')){
            $diseases = $request->input('diseases');
            //error_log(json_encode($diseases));


            $disease_ids = array_column($diseases, 'id');
            //error_log(json_encode($disease_ids));


            $patient->diseases()->sync($disease_ids);
            foreach ($diseases as $disease) {
                //error_log('salviamo la patologia '.$disease['id'].' con le medicine '.json_encode($disease['medicines']));
                $patient->diseases()->find($disease['id'])->pivot->medicines()->sync($disease['medicines']);
            }

            /*
            $patient->tumors()->sync($tumor_ids);

            foreach ($drugs_ids as $tumor_id => $drug_ids) {
                $patient->tumors()->find($tumor_id)->pivot->drugs()->sync($drug_ids);
            }
            */
        }


        /*
        if ($request->input('tumors')){
            $tumors = $request->input('tumors');

            $tumor_ids = array();
            $drugs_ids = array();
            foreach ($tumors as $tumor) {
                if($tumor['id']){
                    if(isset($tumor['stadio']))
                        $tumor_ids[$tumor['id']] = ['type' => $tumor['type'], 'T' => $tumor['stadio']['T'], 'M' => $tumor['stadio']['M'], 'N' => $tumor['stadio']['N']];
                    else
                        $tumor_ids[$tumor['id']] = ['type' => $tumor['type']];

                    if(array_key_exists('drugs',$tumor)){
                        $drug_ids = array();
                        foreach ($tumor['drugs'] as $drug) {
                            $drug_ids[$drug['id']] = [
                                'start_date' =>   array_key_exists('start_date', $drug) ? $drug['start_date'] : new DateTime('today'),
                                'end_date'   =>  array_key_exists('end_date', $drug) ? $drug['end_date'] : null
                            ];
                        }
                        $drugs_ids[$tumor['id']] = $drug_ids;
                    }
                }
            }

        }

        $patient->tumors()->sync($tumor_ids);

        foreach ($drugs_ids as $tumor_id => $drug_ids) {
            $patient->tumors()->find($tumor_id)->pivot->drugs()->sync($drug_ids);
        }
        */

        // Nuova gestione.
        if ($request->input('tumors')){
            error_log('log tumori');

            $tumors = $request->input('tumors');
            error_log(json_encode($tumors));

            //$tumor_ids = array_column($tumors, 'id');
            //error_log('salviamo questi tumori: ' . json_encode($tumor_ids));
            $tumor_ids = array();

            //$patient->tumors()->sync($tumor_ids);
            foreach ($tumors as $tumor){
                if($tumor['id']){
                    $tumor_ids[$tumor['id']] = [
                        'type' => $tumor['type'],
                        //'sede' => $tumor['sede'],
                        'T' => $tumor['stadio'] ? $tumor['stadio']['T'] : null,
                        'M' => $tumor['stadio'] ? $tumor['stadio']['M'] : null,
                        'N' => $tumor['stadio'] ? $tumor['stadio']['N'] : null,
                    ];
                }
            }

            error_log('aggiorniamo i tumori: ' . json_encode(array_keys($tumor_ids)));
            $patient->tumors()->sync($tumor_ids);
            error_log('tumori aggiornati');
            foreach ($tumors as $tumor) {
                $drugs = $tumor['drugs'];
                error_log('adesso forse aggiorniamo il tumore ' . $tumor['id'] . ' con le drugs ' . json_encode(array_column($drugs, 'id')));
                $drug_ids = array();

                foreach($drugs as $drug){
                    $drug_ids[$drug['id']] = [
                        'start_date' =>   array_key_exists('start_date', $drug) && $drug['start_date'] ? $drug['start_date'] : new DateTime('today'),
                        'end_date'   =>  array_key_exists('end_date', $drug) ? $drug['end_date'] : null
                    ];
                }
                error_log('aggiorniamo le droghe per ' . json_encode($tumor['id']) . ' con ' . json_encode($drug_ids));
                $patient->tumors()->find($tumor['id'])->pivot->drugs()->sync($drug_ids);

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
