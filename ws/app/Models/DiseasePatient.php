<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\Relations\Pivot;

class DiseasePatient extends Pivot
{
    /**
     * The medicines that belong to the DiseasePatient
     *
     * @return \Illuminate\Database\Eloquent\Relations\BelongsToMany
     */
    public function medicines(): BelongsToMany
    {
        return $this->belongsToMany(Medicine::class, 'disease_medicine_patient', 'disease_patient_id', 'medicine_id');
    }

    /**
     * Get the patient that owns the DiseasePatient
     *
     * @return \Illuminate\Database\Eloquent\Relations\BelongsTo
     */
    public function patient(): BelongsTo
    {
        return $this->belongsTo(Patient::class, 'patient_id');
    }
}
