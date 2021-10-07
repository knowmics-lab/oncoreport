<?php

namespace App\Http\Controllers;

use App\Http\Resources\DrugResource as ResourcesDrug;
use App\Http\Resources\DrugCollection;
use App\Models\Patient;
use App\Models\PatientTumor;
use Illuminate\Http\Request;

class PatientTumorController extends Controller
{
    public function detach(Request $request, int $patient_id, int $tumor_id, int $drug_id): ResourcesDrug
    {
        $model = PatientTumor::where('patient_id', $patient_id)
                             ->where('tumor_id', $tumor_id)
                             ->firstOrFail();
        $reasons = (array)$request->input('reasons', []);
        $comment = $request->input('comment', '');
        $drug = $model->drugs()->findOrFail($drug_id);
        $model->drugs()->updateExistingPivot($drug_id, [
            'end_date' => now(),
            'comment'  => $comment,
        ]);
        if ($drug) {
            $drug->pivot->reasons()->sync($reasons);
        }

        return new ResourcesDrug($model->drugs()->findOrFail($drug_id));
    }

    public function detachAll(Request $request, $patient_id, $drug_id): DrugCollection
    {
        $reasons = (array)$request->input('reasons', []);
        $comment = $request->input('comment', '');
        $models = PatientTumor::where('patient_id', $patient_id)->get();
        foreach ($models as $model) {
            $drug = $model->drugs()->find($drug_id);
            if ($drug) {
                $model->drugs()->updateExistingPivot($drug->id, [
                    'end_date' => now(),
                    'comment'  => $comment,
                ]);
                $drug->pivot->reasons()->sync($reasons);
            }
        }

        return new DrugCollection(Patient::findOrFail($patient_id)->drugs()->get());
    }
}
