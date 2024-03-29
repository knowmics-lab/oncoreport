<?php
/**
 * Oncoreport Web Service
 *
 * @author S. Alaimo, Ph.D. <alaimos at gmail dot com>
 */

namespace App\Models;

use App\Constants;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Fortify\TwoFactorAuthenticatable;
use Laravel\Jetstream\HasProfilePhoto;
use Laravel\Sanctum\HasApiTokens;

class User extends Authenticatable
{
    use HasApiTokens;
    use HasFactory;
    use HasProfilePhoto;
    use Notifiable;
    use TwoFactorAuthenticatable;

    /**
     * The attributes that are mass assignable.
     *
     * @var array
     */
    protected $fillable = [
        'name',
        'email',
        'password',
        'role',
    ];

    /**
     * The attributes that should be hidden for arrays.
     *
     * @var array
     */
    protected $hidden = [
        'password',
        'remember_token',
        'two_factor_recovery_codes',
        'two_factor_secret',
    ];

    /**
     * The attributes that should be cast to native types.
     *
     * @var array
     */
    protected $casts = [
        'email_verified_at' => 'datetime',
    ];

    /**
     * The accessors to append to the model's array form.
     *
     * @var array
     */
    protected $appends = [
        'profile_photo_url',
    ];

    /**
     * @return \Illuminate\Database\Eloquent\Relations\HasMany
     */
    public function jobs(): HasMany
    {
        return $this->hasMany(Job::class, 'owner_id');
    }

    /**
     * @return \Illuminate\Database\Eloquent\Relations\HasMany
     */
    public function patients(): HasMany
    {
        return $this->hasMany(Patient::class, 'owner_id');
    }

    public function getIsAdminAttribute(): bool
    {
        return $this->role === Constants::ADMIN;
    }

    /**
     * Returns some statistics about the user or the system if the user is an administrator.
     *
     * @return array
     */
    public function statistics(): array
    {
        $stats = [];
        if ($this->is_admin) {
            $stats['jobs'] = [
                'all'        => Job::count(),
                'ready'      => Job::whereStatus(Constants::READY)->count(),
                'queued'     => Job::whereStatus(Constants::QUEUED)->count(),
                'processing' => Job::whereStatus(Constants::PROCESSING)->count(),
                'failed'     => Job::whereStatus(Constants::FAILED)->count(),
                'completed'  => Job::whereStatus(Constants::COMPLETED)->count(),
            ];
        } else {
            $stats['jobs'] = [
                'all'        => Job::whereUserId($this->id)->count(),
                'ready'      => Job::whereUserId($this->id)->whereStatus(Constants::READY)->count(),
                'queued'     => Job::whereUserId($this->id)->whereStatus(Constants::QUEUED)->count(),
                'processing' => Job::whereUserId($this->id)->whereStatus(Constants::PROCESSING)->count(),
                'failed'     => Job::whereUserId($this->id)->whereStatus(Constants::FAILED)->count(),
                'completed'  => Job::whereUserId($this->id)->whereStatus(Constants::COMPLETED)->count(),
            ];
        }

        return $stats;
    }


}
