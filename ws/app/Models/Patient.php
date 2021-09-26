<?php
/**
 * Oncoreport Web Service
 *
 * @author S. Alaimo, Ph.D. <alaimos at gmail dot com>
 */

namespace App\Models;

use Auth;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Foundation\Auth\User as Model;

//use Illuminate\Database\Eloquent\Model;

/**
 * @mixin IdeHelperPatient
 */
class Patient extends Model
{
    use HasFactory;

    public const VALID_GENDERS = ['m', 'f'];
    protected $guarded = ['email'];
    protected $hidden = [
        'password',
        'remember_token',
    ];
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
        'email',
        'fiscal_number',
        'password',
    ];
    /**
     * The accessors to append to the model's array form.
     *
     * @var array
     */
    protected $appends = [
        'full_name',
    ];

    public function getAuthPassword()
    {
        return $this->password;
    }

    /**
     * Scope a query to filter for job_type.
     * If a job is a group then it uses the type of the first grouped job.
     *
     * @param  \Illuminate\Database\Eloquent\Builder  $query
     * @param  \App\Models\User|null  $user
     * @param  boolean  $enforce
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

    public function tumors()
    {
        return $this->belongsToMany(Tumor::class)->using(PatientTumor::class)->withPivot('id')->withTimestamps(
        )->withPivot(['type', 'T', 'M', 'N']);
    }

    public function drugs()
    {
        return Drug::join('drug_patient_tumor', 'drug_patient_tumor.drug_id', '=', 'drugs.id')->join(
            'patient_tumor',
            'patient_tumor.id',
            '=',
            'drug_patient_tumor.patient_tumor_id'
        )->where('patient_id', $this->id)->where('drug_patient_tumor.end_date', null)->select(
            'drugs.id',
            'drugs.name'
        )->distinct();

        return $this->hasManyThrough(Drug::class, PatientTumor::class, 'patient_id', 'id');
    }

    public function currentDrugs()
    {
        return Drug::join('drug_patient_tumor', 'drug_patient_tumor.drug_id', '=', 'drugs.id')->join(
            'patient_tumor',
            'patient_tumor.id',
            '=',
            'drug_patient_tumor.patient_tumor_id'
        )->where('patient_id', $this->id)->where('drug_patient_tumor.end_date', null)->select(
            'drugs.id',
            'drugs.name'
        )->distinct();
    }


    public function pastDrugs()
    {
        return Drug::join('drug_patient_tumor', 'drug_patient_tumor.drug_id', '=', 'drugs.id')->join(
            'patient_tumor',
            'patient_tumor.id',
            '=',
            'drug_patient_tumor.patient_tumor_id'
        )->where('patient_id', $this->id)->where('drug_patient_tumor.end_date', null)->select(
            'drugs.id',
            'drugs.name'
        )->distinct();
    }


    /**
     * The diseases that belong to the Patient
     *
     * @return \Illuminate\Database\Eloquent\Relations\BelongsToMany
     */
    public function diseases(): BelongsToMany
    {
        return $this->belongsToMany(Disease::class)->using(DiseasePatient::class)->withPivot('id');
    }

    public function medicines()
    {
        return Medicine::join('disease_medicine_patient', 'medicines.id', '=', 'disease_medicine_patient.medicine_id')
                       ->join(
                           'disease_patient',
                           'disease_medicine_patient.disease_patient_id',
                           '=',
                           'disease_patient.id'
                       )
                       ->join('patients', 'disease_patient.patient_id', '=', 'patients.id')
                       ->join(
                           'disease_medicine_patient_reason',
                           'disease_medicine_patient_reason.disease_medicine_patient_id',
                           '=',
                           'disease_medicine_patient.id'
                       )
                       ->join('reasons', 'disease_medicine_patient_reason.reason_id', '=', 'reasons.id')
                       ->select('medicines.id', 'medicines.name', 'reasons.name as reason')->distinct()->where(
                'patients.id',
                $this->id
            );

        return $this->hasManyThrough(Medicine::class, DiseasePatient::class, 'patient_id', 'id');
    }

}
