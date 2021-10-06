<?php
/**
 * Oncoreport Web Service
 *
 * @author S. Alaimo, Ph.D. <alaimos at gmail dot com>
 */

namespace App\Models;

use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Foundation\Auth\User as Model;

class PatientDrug extends Model
{

    protected $fillable = [
        'patient_id',
        'drug_id',
        'patient_disease_id',
        'start_date',
        'end_date',
        'comment',
    ];

    protected $casts = [
        'start_date' => 'date',
        'end_date'   => 'date',
    ];

    protected $with = [
        'drug',
        'suspensionReasons',
    ];

    public function patient(): BelongsTo
    {
        return $this->belongsTo(Patient::class);
    }

    public function drug(): BelongsTo
    {
        return $this->belongsTo(Drug::class);
    }

    public function disease(): BelongsTo
    {
        return $this->belongsTo(PatientDisease::class, 'patient_disease_id');
    }

    public function suspensionReasons(): BelongsToMany
    {
        return $this->belongsToMany(SuspensionReason::class, 'patient_drug_suspension_reason');
    }
}
