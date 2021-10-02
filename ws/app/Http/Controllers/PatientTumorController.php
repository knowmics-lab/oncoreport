<?php

namespace App\Http\Controllers;

use App\Http\Resources\Drug as ResourcesDrug;
use App\Http\Resources\DrugCollection;
use App\Models\Patient;
use App\Models\PatientTumor;
use DateTime;
use Illuminate\Http\Request;

class PatientTumorController extends Controller
{
    public function detach($patient_id, $tumor_id, $drug_id, Request $request)
    {
        $reasons = json_decode($request->get('reasons', []));
        $model = PatientTumor::where('patient_id', '=', $patient_id)->where('tumor_id', '=', $tumor_id)->firstOrFail();
        $drug = $model->drugs()->findOrFail($drug_id);
        $model->drugs()->updateExistingPivot($drug->id, ['end_date' => new DateTime('today')]);

        $comment = $request->get('comment', null);
        if ($comment) {
            $model->drugs()->updateExistingPivot($drug->id, ['comment' => $comment]);
        }

        $drug->pivot->reasons()->sync($reasons);

        return new ResourcesDrug($model->drugs()->findOrFail($drug_id));

        return $model->drugs;
    }

    public function detachAll($patient_id, $drug_id, Request $request)
    {
        #error_log('ciao');
        $reasons = json_decode($request->get('reasons', []));

        #error_log("comment: " . json_encode($request->get("comment", '')));
        #error_log('togliamo ' . $drug_id . ' da ' . $patient_id . ' per queste ragioni ' . json_encode($reasons));


        $models = PatientTumor::where('patient_id', '=', $patient_id)->get();
        #foreach ($models as $model) {
        #    error_log(json_encode('controlliamo ' . $model->id));
        #}

        foreach ($models as $model) {
            #error_log(json_encode($model->drugs));
            $drug = $model->drugs()->find($drug_id);
            #error_log("abbiamo trovato " . json_encode($drug));
            if ($drug) {
                #error_log('togliamo ' . $drug->id . ' da ' . $model->tumor_id);
                $result = $model->drugs()->updateExistingPivot($drug->id, ['end_date' => new DateTime('today')]);
                #error_log(json_encode($result));
                $drug->pivot->reasons()->sync($reasons);
                #error_log('fatto tutto');

                $comment = $request->get("comment", null);
                if ($comment) {
                    $model->drugs()->updateExistingPivot($drug->id, ['comment' => $comment]);
                }
            }
        }

        return new DrugCollection(Patient::findOrFail($patient_id)->drugs()->get());
    }
}
