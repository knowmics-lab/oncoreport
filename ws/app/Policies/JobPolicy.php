<?php
/**
 * Oncoreport Web Service
 *
 * @author S. Alaimo, Ph.D. <alaimos at gmail dot com>
 */

namespace App\Policies;

use App\Constants;
use App\Models\Job;
use App\Models\User;
use Illuminate\Auth\Access\HandlesAuthorization;

class JobPolicy
{
    use HandlesAuthorization;

    /**
     * Determine whether the user can view any jobs.
     *
     * @param  \App\Models\User  $user
     *
     * @return bool
     */
    public function viewAny(User $user): bool
    {
        return true;
    }

    /**
     * Determine whether the user can view the job.
     *
     * @param  \App\Models\User  $user
     * @param  \App\Models\Job  $job
     *
     * @return bool
     */
    public function view(User $user, Job $job): bool
    {
        $role = $user->role;

        return
            // Admins or technical staff can view all jobs
            in_array($role, [Constants::ADMIN, Constants::TECHNICAL], true) ||
            // Doctors can view their own patient's jobs
            ($role === Constants::DOCTOR && ($job->owner_id === null || $job->owner_id === $user->id)) ||
            // Patients can view their own data
            ($role === Constants::PATIENT && $job->patient_id === $user->id);
    }

    /**
     * Determine whether the user can create jobs.
     *
     * @param  \App\Models\User  $user
     *
     * @return bool
     */
    public function create(User $user): bool
    {
        return $user->role !== Constants::PATIENT;
    }

    /**
     * Determine whether the user can update the job.
     *
     * @param  \App\Models\User  $user
     * @param  \App\Models\Job  $job
     *
     * @return bool
     */
    public function update(User $user, Job $job): bool
    {
        $role = $user->role;

        return
            // Admins or technical staff can update all jobs
            in_array($role, [Constants::ADMIN, Constants::TECHNICAL], true) ||
            // Doctors can update their own patient's jobs
            ($role === Constants::DOCTOR && ($job->owner_id === null || $job->owner_id === $user->id));
    }

    /**
     * Determine whether the user can delete the job.
     *
     * @param  \App\Models\User  $user
     * @param  \App\Models\Job  $job
     *
     * @return bool
     */
    public function delete(User $user, Job $job): bool
    {
        $role = $user->role;

        return
            // Admins or technical staff can delete all jobs
            in_array($role, [Constants::ADMIN, Constants::TECHNICAL], true) ||
            // Doctors can delete their own patient's jobs
            ($role === Constants::DOCTOR && ($job->owner_id === null || $job->owner_id === $user->id)) ||
            // Patients can delete their own data
            ($role === Constants::PATIENT && $job->patient_id === $user->id);
    }

    /**
     * Determine whether the user can submit the job.
     *
     * @param  \App\Models\User  $user
     * @param  \App\Models\Job  $job
     *
     * @return bool
     */
    public function submit(User $user, Job $job): bool
    {
        $role = $user->role;

        return
            // Admins or technical staff can submit all jobs
            in_array($role, [Constants::ADMIN, Constants::TECHNICAL], true) ||
            // Doctors can submit their own patient's jobs
            ($role === Constants::DOCTOR && ($job->owner_id === null || $job->owner_id === $user->id));
    }

    /**
     * Determine whether the user can upload files to a job.
     *
     * @param  \App\Models\User  $user
     * @param  \App\Models\Job  $job
     *
     * @return bool
     */
    public function upload(User $user, Job $job): bool
    {
        $role = $user->role;

        return
            // Admins or technical staff can upload files to all jobs
            in_array($role, [Constants::ADMIN, Constants::TECHNICAL], true) ||
            // Doctors can upload files to their own patient's jobs
            ($role === Constants::DOCTOR && ($job->owner_id === null || $job->owner_id === $user->id));
    }
}
