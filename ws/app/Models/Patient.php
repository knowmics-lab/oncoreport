<?php
/**
 * Oncoreport Web Service
 *
 * @author S. Alaimo, Ph.D. <alaimos at gmail dot com>
 */

namespace App\Models;

use App\Constants;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Foundation\Auth\User as Model;
use Illuminate\Support\Facades\Auth;

class Patient extends Model
{

    protected $fillable = [
        'code',
        'first_name',
        'last_name',
        'gender',
        'age',
        'email',
        'fiscal_number',
        'telephone',
        'city',
        'user_id',
        'owner_id',
        'primary_disease_id',
    ];

    protected $appends = [
        'full_name',
    ];

    protected $with = [
        'primaryDisease',
    ];

    /**
     * Scope a query to show only visible patients.
     * If $user is an admin or a technician, no limitation are applied.
     * If $user is a patient, shows only his own data.
     * If $user is a doctor, it shows patients where the owner_id matches with $user->id
     *
     * @param  \Illuminate\Database\Eloquent\Builder  $query
     * @param  \App\Models\User|null  $user
     *
     * @return \Illuminate\Database\Eloquent\Builder
     */
    public function scopeByUser(Builder $query, ?User $user = null): Builder
    {
        if ($user === null && !Auth::check()) {
            return $query->whereRaw('1 <> 1');
        }
        if ($user === null) {
            $user = Auth::user();
        }
        if ($user->role === Constants::DOCTOR) {
            return $query->where(
                static function (Builder $q) use ($user) {
                    $q->whereNull('owner_id')->orWhere('owner_id', $user->id);
                }
            );
        }
        if ($user->role === Constants::PATIENT) {
            return $query->whereNotNull('user_id')->where('user_id', $user->id);
        }

        return $query;
    }

    /**
     * Returns the full name of a patient
     *
     * @return string
     */
    public function getFullNameAttribute(): string
    {
        return "$this->first_name $this->last_name";
    }

    public function loadRelationships(): self
    {
        return $this->load(['primaryDisease', 'diseases', 'drugs']);
    }

    public function diseases(): HasMany
    {
        return $this->hasMany(PatientDisease::class);
    }

    public function primaryDisease(): BelongsTo
    {
        return $this->belongsTo(PatientDisease::class, 'primary_disease_id');
    }

    public function drugs(): HasMany
    {
        return $this->hasMany(PatientDrug::class);
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class, 'user_id');
    }

    public function owner(): BelongsTo
    {
        return $this->belongsTo(User::class, 'owner_id');
    }

}
