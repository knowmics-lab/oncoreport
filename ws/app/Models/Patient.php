<?php
/**
 * Oncoreport Web Service
 *
 * @author S. Alaimo, Ph.D. <alaimos at gmail dot com>
 */

namespace App\Models;

use App\Constants;
use Auth;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;
use Illuminate\Foundation\Auth\User as Model;

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
                    $q->whereNull('user_id')->orWhere('user_id', $user->id);
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

    public function diseases(): HasMany
    {
        return $this->hasMany(PatientDisease::class);
    }

    public function primaryDisease(): HasOne
    {
        return $this->hasOne(PatientDisease::class, 'primary_disease_id');
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

//
//    public function currentDrugs()
//    {
//        return Drug::join('drug_patient_tumor', 'drug_patient_tumor.drug_id', '=', 'drugs.id')->join(
//            'patient_tumor',
//            'patient_tumor.id',
//            '=',
//            'drug_patient_tumor.patient_tumor_id'
//        )->where('patient_id', $this->id)->where('drug_patient_tumor.end_date', null)->select(
//            'drugs.id',
//            'drugs.name'
//        )->distinct();
//    }
//
//
//    public function pastDrugs()
//    {
//        return Drug::join('drug_patient_tumor', 'drug_patient_tumor.drug_id', '=', 'drugs.id')->join(
//            'patient_tumor',
//            'patient_tumor.id',
//            '=',
//            'drug_patient_tumor.patient_tumor_id'
//        )->where('patient_id', $this->id)->where('drug_patient_tumor.end_date', null)->select(
//            'drugs.id',
//            'drugs.name'
//        )->distinct();
//    }
//
//
//    /**
//     * The diseases that belong to the Patient
//     *
//     * @return \Illuminate\Database\Eloquent\Relations\BelongsToMany
//     */
//    public function diseases(): BelongsToMany
//    {
//        return $this->belongsToMany(Disease::class)->using(DiseasePatient::class)->withPivot('id');
//    }
//
//    public function medicines()
//    {
//        return Medicine::join('disease_medicine_patient', 'medicines.id', '=', 'disease_medicine_patient.medicine_id')
//                       ->join(
//                           'disease_patient',
//                           'disease_medicine_patient.disease_patient_id',
//                           '=',
//                           'disease_patient.id'
//                       )
//                       ->join('patients', 'disease_patient.patient_id', '=', 'patients.id')
//                       ->join(
//                           'disease_medicine_patient_reason',
//                           'disease_medicine_patient_reason.disease_medicine_patient_id',
//                           '=',
//                           'disease_medicine_patient.id'
//                       )
//                       ->join('reasons', 'disease_medicine_patient_reason.reason_id', '=', 'reasons.id')
//                       ->select('medicines.id', 'medicines.name', 'reasons.name as reason')->distinct()->where(
//                'patients.id',
//                $this->id
//            );
//
//        return $this->hasManyThrough(Medicine::class, DiseasePatient::class, 'patient_id', 'id');
//    }

}
