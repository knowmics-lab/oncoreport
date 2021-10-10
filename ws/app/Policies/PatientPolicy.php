<?php
/**
 * Oncoreport Web Service
 *
 * @author S. Alaimo, Ph.D. <alaimos at gmail dot com>
 */

namespace App\Policies;

use App\Constants;
use App\Models\Patient;
use App\Models\User;
use Illuminate\Auth\Access\HandlesAuthorization;

class PatientPolicy
{
    use HandlesAuthorization;

    /**
     * Determine whether the user can view any models.
     *
     * @param  \App\Models\User  $user
     *
     * @return bool
     */
    public function viewAny(User $user): bool
    {
        // Patients can view only their own data
        return $user->role !== Constants::PATIENT;
    }

    /**
     * Determine whether the user can view the model.
     *
     * @param  \App\Models\User  $user
     * @param  \App\Models\Patient  $patient
     *
     * @return bool
     */
    public function view(User $user, Patient $patient): bool
    {
        $role = $user->role;

        return
            // Admins or technical staff can view all patients
            in_array($role, [Constants::ADMIN, Constants::TECHNICAL], true) ||
            // Doctors can view their own patients
            ($role === Constants::DOCTOR && ($patient->owner_id === null || $patient->owner_id === $user->id)) ||
            // Patients can view their own data
            ($role === Constants::PATIENT && $patient->user_id === $user->id);
    }

    /**
     * Determine whether the user can create models.
     *
     * @param  \App\Models\User  $user
     *
     * @return bool
     */
    public function create(User $user): bool
    {
        // Only Admins and Doctors can create new patients
        return in_array($user->role, [Constants::ADMIN, Constants::DOCTOR], true);
    }

    /**
     * Determine whether the user can update the model.
     *
     * @param  \App\Models\User  $user
     * @param  \App\Models\Patient  $patient
     *
     * @return bool
     */
    public function update(User $user, Patient $patient): bool
    {
        return
            // Admins can update all patients
            $user->is_admin ||
            // Doctors can update their own patients
            ($user->role === Constants::DOCTOR && ($patient->owner_id === null || $patient->owner_id === $user->id));
        // Technical staff or patients are not allowed to update
    }

    /**
     * Determine whether the user can delete the model.
     *
     * @param  \App\Models\User  $user
     * @param  \App\Models\Patient  $patient
     *
     * @return bool
     */
    public function delete(User $user, Patient $patient): bool
    {
        $role = $user->role;

        return
            // Admins can delete all patients
            $user->is_admin ||
            // Doctors can delete their own patients
            ($role === Constants::DOCTOR && ($patient->owner_id === null || $patient->owner_id === $user->id)) ||
            // Patients can delete their own data
            ($role === Constants::PATIENT && $patient->user_id === $user->id);
        // The technical staff is not allowed to delete patients
    }

}
