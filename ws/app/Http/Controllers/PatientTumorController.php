<?php

namespace App\Http\Controllers;

use App\Http\Resources\Drug as ResourcesDrug;
use App\Http\Resources\DrugCollection;
use App\Http\Resources\Patient as ResourcesPatient;
use App\Models\Drug;
use App\Models\Patient;
use App\Models\PatientTumor;
use DateTime;
use Illuminate\Http\Request;

use App\Http\Resources\Patient as PatientResource;
use App\Http\Resources\PatientCollection;
use Auth;
use Response;

class PatientTumorController extends Controller
{
    public function detach($patient_id, $tumor_id, $drug_id, Request $request){


        $reasons = json_decode($request->get('reasons', []));
        error_log('ciao');
        error_log(json_encode($reasons));
        $model = PatientTumor::where('patient_id','=',$patient_id)->where('tumor_id','=',$tumor_id)->firstOrFail();
        $drug = $model->drugs()->findOrFail($drug_id);
        $model->drugs()->updateExistingPivot($drug->id, ['end_date' => new DateTime('today')]);

        $drug->pivot->reasons()->sync($reasons);

        return new ResourcesDrug($model->drugs()->findOrFail($drug_id));
        return $model->drugs;

    }

    public function detachAll($patient_id, $drug_id, Request $request){

        $reasons = json_decode($request->get('reasons', []));
        error_log('ciao, togliamo ' . $drug_id . ' da ' . $patient_id);
        error_log(json_encode($reasons));
        $models = PatientTumor::where('patient_id','=',$patient_id)->get();




        foreach ($models as $model) {
            error_log(json_encode($model->drugs));
            $drug = $model->drugs()->find($drug_id);
            if($drug){
                error_log('togliamo ' . $drug->name . ' da ' . $model->tumor_id);
                $model->drugs()->updateExistingPivot($drug->id, ['end_date' => new DateTime('today')]);
                $drug->pivot->reasons()->sync($reasons);
            }
        }

        //return new PatientResource(Patient::findOrFail($patient_id));
        return new DrugCollection(Patient::findOrFail($patient_id)->drugs()->get());
        //return new ResourcesDrug($model->drugs()->findOrFail($drug_id));
        //return $model->drugs;

    }
}
