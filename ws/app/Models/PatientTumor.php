<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Relations\Pivot;

class PatientTumor extends Pivot
{
    public function drugs()
    {
        return $this->belongsToMany(Drug::class, 'drug_patient_tumor', 'patient_tumor_id', 'drug_id')->using(
            DrugPatientTumor::class
        )->withPivot('id')->withPivot(['start_date', 'end_date', 'comment']);

        //return $this->belongsToMany(Drug::class, 'drug_patient_tumor', 'patient_tumor_id', 'drug_id')->withPivot(['start_date','end_date']);
        //->join('reasons','drug_patient_tumor.reason_id','=','reasons.id')->select('reasons.name');
    }

    public function locations()
    {
        return $this->belongsToMany(Location::class, 'location_patient_tumor', 'patient_tumor_id', 'location_id');
    }
}
