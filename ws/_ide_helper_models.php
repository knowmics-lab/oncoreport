<?php

// @formatter:off
/**
 * A helper file for your Eloquent Models
 * Copy the phpDocs from this file to the correct Model,
 * And remove them from this file, to prevent double declarations.
 *
 * @author Barry vd. Heuvel <barryvdh@gmail.com>
 */


namespace App\Models{
/**
 * App\Models\Disease
 *
 * @property int $id
 * @property string $name
 * @property \Illuminate\Support\Carbon|null $created_at
 * @property \Illuminate\Support\Carbon|null $updated_at
 * @property-read \Illuminate\Database\Eloquent\Collection|\App\Models\Patient[] $patients
 * @property-read int|null $patients_count
 * @method static \Illuminate\Database\Eloquent\Builder|Disease newModelQuery()
 * @method static \Illuminate\Database\Eloquent\Builder|Disease newQuery()
 * @method static \Illuminate\Database\Eloquent\Builder|Disease query()
 * @method static \Illuminate\Database\Eloquent\Builder|Disease whereCreatedAt($value)
 * @method static \Illuminate\Database\Eloquent\Builder|Disease whereId($value)
 * @method static \Illuminate\Database\Eloquent\Builder|Disease whereName($value)
 * @method static \Illuminate\Database\Eloquent\Builder|Disease whereUpdatedAt($value)
 * @mixin \Eloquent
 */
	class IdeHelperDisease extends \Eloquent {}
}

namespace App\Models{
/**
 * App\Models\Job
 *
 * @property int $id
 * @property string $sample_code
 * @property string $name
 * @property string $job_type
 * @property string $status
 * @property array $job_parameters
 * @property array $job_output
 * @property string $log
 * @property int|null $patient_id
 * @property int $user_id
 * @property \Illuminate\Support\Carbon|null $created_at
 * @property \Illuminate\Support\Carbon|null $updated_at
 * @property-read \App\Models\Patient|null $patient
 * @property-read \App\Models\User $user
 * @method static Builder|Job byPatient(\App\Models\Patient $patient)
 * @method static Builder|Job deepTypeFilter($type)
 * @method static Builder|Job newModelQuery()
 * @method static Builder|Job newQuery()
 * @method static Builder|Job query()
 * @method static Builder|Job whereCreatedAt($value)
 * @method static Builder|Job whereId($value)
 * @method static Builder|Job whereJobOutput($value)
 * @method static Builder|Job whereJobParameters($value)
 * @method static Builder|Job whereJobType($value)
 * @method static Builder|Job whereLog($value)
 * @method static Builder|Job whereName($value)
 * @method static Builder|Job wherePatientId($value)
 * @method static Builder|Job whereSampleCode($value)
 * @method static Builder|Job whereStatus($value)
 * @method static Builder|Job whereUpdatedAt($value)
 * @method static Builder|Job whereUserId($value)
 * @mixin \Eloquent
 */
	class IdeHelperJob extends \Eloquent {}
}

namespace App\Models{
/**
 * App\Models\Patient
 *
 * @property int $id
 * @property string $code
 * @property string $first_name
 * @property string $last_name
 * @property string $gender
 * @property int $age
 * @property int $disease_id
 * @property int|null $user_id
 * @property \Illuminate\Support\Carbon|null $created_at
 * @property \Illuminate\Support\Carbon|null $updated_at
 * @property-read \App\Models\Disease $disease
 * @property-read string $full_name
 * @property-read \App\Models\User|null $user
 * @method static Builder|Patient byUser(\App\Models\User $user = null, $enforce = false)
 * @method static Builder|Patient newModelQuery()
 * @method static Builder|Patient newQuery()
 * @method static Builder|Patient query()
 * @method static Builder|Patient whereAge($value)
 * @method static Builder|Patient whereCode($value)
 * @method static Builder|Patient whereCreatedAt($value)
 * @method static Builder|Patient whereDiseaseId($value)
 * @method static Builder|Patient whereFirstName($value)
 * @method static Builder|Patient whereGender($value)
 * @method static Builder|Patient whereId($value)
 * @method static Builder|Patient whereLastName($value)
 * @method static Builder|Patient whereUpdatedAt($value)
 * @method static Builder|Patient whereUserId($value)
 * @mixin \Eloquent
 */
	class IdeHelperPatient extends \Eloquent {}
}

namespace App\Models{
/**
 * App\Models\User
 *
 * @property int $id
 * @property string $name
 * @property string $email
 * @property \Illuminate\Support\Carbon|null $email_verified_at
 * @property string $password
 * @property string|null $two_factor_secret
 * @property string|null $two_factor_recovery_codes
 * @property string|null $remember_token
 * @property int|null $current_team_id
 * @property string|null $profile_photo_path
 * @property \Illuminate\Support\Carbon|null $created_at
 * @property \Illuminate\Support\Carbon|null $updated_at
 * @property bool $admin
 * @property-read string $profile_photo_url
 * @property-read \Illuminate\Database\Eloquent\Collection|\App\Models\Job[] $jobs
 * @property-read int|null $jobs_count
 * @property-read \Illuminate\Notifications\DatabaseNotificationCollection|\Illuminate\Notifications\DatabaseNotification[] $notifications
 * @property-read int|null $notifications_count
 * @property-read \Illuminate\Database\Eloquent\Collection|\App\Models\Patient[] $patients
 * @property-read int|null $patients_count
 * @property-read \Illuminate\Database\Eloquent\Collection|\Laravel\Sanctum\PersonalAccessToken[] $tokens
 * @property-read int|null $tokens_count
 * @method static \Illuminate\Database\Eloquent\Builder|User newModelQuery()
 * @method static \Illuminate\Database\Eloquent\Builder|User newQuery()
 * @method static \Illuminate\Database\Eloquent\Builder|User query()
 * @method static \Illuminate\Database\Eloquent\Builder|User whereAdmin($value)
 * @method static \Illuminate\Database\Eloquent\Builder|User whereCreatedAt($value)
 * @method static \Illuminate\Database\Eloquent\Builder|User whereCurrentTeamId($value)
 * @method static \Illuminate\Database\Eloquent\Builder|User whereEmail($value)
 * @method static \Illuminate\Database\Eloquent\Builder|User whereEmailVerifiedAt($value)
 * @method static \Illuminate\Database\Eloquent\Builder|User whereId($value)
 * @method static \Illuminate\Database\Eloquent\Builder|User whereName($value)
 * @method static \Illuminate\Database\Eloquent\Builder|User wherePassword($value)
 * @method static \Illuminate\Database\Eloquent\Builder|User whereProfilePhotoPath($value)
 * @method static \Illuminate\Database\Eloquent\Builder|User whereRememberToken($value)
 * @method static \Illuminate\Database\Eloquent\Builder|User whereTwoFactorRecoveryCodes($value)
 * @method static \Illuminate\Database\Eloquent\Builder|User whereTwoFactorSecret($value)
 * @method static \Illuminate\Database\Eloquent\Builder|User whereUpdatedAt($value)
 * @mixin \Eloquent
 */
	class IdeHelperUser extends \Eloquent {}
}

