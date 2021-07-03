<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\Relations\HasManyThrough;

class Drug extends Model
{
    protected $fillable = ['name'];
    use HasFactory;



    /**
     * The patientTumor that belong to the Drug
     *
     * @return \Illuminate\Database\Eloquent\Relations\BelongsToMany
     */
    public function patientTumor(): BelongsToMany
    {
        return $this->belongsToMany(PatientTumor::class, 'drug_patient_tumor', 'drug_id','patient_tumor_id' );
    }

}
