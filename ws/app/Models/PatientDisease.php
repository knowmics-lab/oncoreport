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
        'location_id',
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
        'location',
    ];

    public function patient(): BelongsTo
    {
        return $this->belongsTo(Patient::class);
    }

    public function disease(): BelongsTo
    {
        return $this->belongsTo(Disease::class);
    }

    public function location(): BelongsTo
    {
        return $this->belongsTo(Location::class);
    }
}
