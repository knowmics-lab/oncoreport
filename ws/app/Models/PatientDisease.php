<?php
/**
 * Oncoreport Web Service
 *
 * @author S. Alaimo, Ph.D. <alaimos at gmail dot com>
 */

namespace App\Models;

use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Foundation\Auth\User as Model;

class PatientDisease extends Model
{

    protected $fillable = [
        'patient_id',
        'disease_id',
        'type',
        'T',
        'N',
        'M',
        'start_date',
        'end_date',
    ];

    protected $casts = [
        'T'          => 'int',
        'N'          => 'int',
        'M'          => 'int',
        'start_date' => 'date',
        'end_date'   => 'date',
    ];

    protected $with = [
        'disease',
    ];

    public function patient(): BelongsTo
    {
        return $this->belongsTo(Patient::class);
    }

    public function disease(): BelongsTo
    {
        return $this->belongsTo(Disease::class);
    }

    public function getStageStringAttribute(): string
    {
        $stage = "";
        if ($this->T) {
            $stage .= 'T: ' . $this->T;
        }
        if ($this->N) {
            $stage .= 'N: ' . $this->N;
        }
        if ($this->M) {
            $stage .= 'M: ' . $this->M;
        }

        return $stage;
    }
}
