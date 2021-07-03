<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\Relations\Pivot;

class DrugPatientTumor extends Pivot
{
    /**
     * The reasons that belong to the DrugPatientTumor
     *
     * @return \Illuminate\Database\Eloquent\Relations\BelongsToMany
     */
    public function reasons(): BelongsToMany
    {
        return $this->belongsToMany(Reason::class, 'drug_patient_tumor_reason','drug_patient_tumor_id','reason_id');
    }
}
