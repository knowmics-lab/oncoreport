<?php

namespace App\Models;

use Auth;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

/**
 * @mixin IdeHelperPatient
 */
class Patient extends Model
{
    use HasFactory;

    public const VALID_GENDERS = ['m', 'f'];

    /**
     * The attributes that are mass assignable.
     *
     * @var array
     */
    protected $fillable = [
        'code',
        'first_name',
        'last_name',
        'gender',
        'age',
        'disease_id',
        'user_id',
    ];

    /**
     * The accessors to append to the model's array form.
     *
     * @var array
     */
    protected $appends = [
        'full_name',
    ];

    /**
     * Scope a query to filter for job_type.
     * If a job is a group then it uses the type of the first grouped job.
     *
     * @param \Illuminate\Database\Eloquent\Builder $query
     * @param \App\Models\User|null                 $user
     * @param boolean                               $enforce
     *
     * @return \Illuminate\Database\Eloquent\Builder
     * @noinspection CallableParameterUseCaseInTypeContextInspection
     */
    public function scopeByUser(Builder $query, ?User $user = null, bool $enforce = false): Builder
    {
        if (!Auth::check()) {
            return $query->whereRaw('1 <> 1');
        }
        if ($user === null) {
            $user = Auth::user();
        }
        if (!$enforce && $user->admin) {
            return $query;
        }

        return $query->where(
            static function (Builder $q) use ($user) {
                $q->whereNull('user_id')->orWhere('user_id', '=', $user->id);
            }
        );
    }

    /**
     * Returns the full name of a patient
     *
     * @return string
     */
    public function getFullNameAttribute(): string
    {
        return "{$this->first_name} {$this->last_name}";
    }

    /**
     * @return \Illuminate\Database\Eloquent\Relations\BelongsTo
     */
    public function disease(): BelongsTo
    {
        return $this->belongsTo(Disease::class, 'disease_id', 'id');
    }

    /**
     * @return \Illuminate\Database\Eloquent\Relations\BelongsTo
     */
    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class, 'user_id', 'id');
    }


}
