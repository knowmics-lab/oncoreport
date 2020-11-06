<?php

namespace App\Policies;

use App\Models\Disease;
use App\Models\User;
use Illuminate\Auth\Access\HandlesAuthorization;

/**
 * Policy for Disease models: all users can view any disease but no changes can be made since
 * they are strictly tied with the underlying application
 * @package App\Policies
 */
class DiseasePolicy
{
    use HandlesAuthorization;

    /**
     * Determine whether the user can view any models.
     *
     * @param \App\Models\User $user
     *
     * @return mixed
     */
    public function viewAny(User $user)
    {
        return true;
    }

    /**
     * Determine whether the user can view the model.
     *
     * @param \App\Models\User    $user
     * @param \App\Models\Disease $disease
     *
     * @return mixed
     */
    public function view(User $user, Disease $disease)
    {
        return true;
    }

    /**
     * Determine whether the user can create models.
     *
     * @param \App\Models\User $user
     *
     * @return mixed
     */
    public function create(User $user)
    {
        return false;
    }

    /**
     * Determine whether the user can update the model.
     *
     * @param \App\Models\User    $user
     * @param \App\Models\Disease $disease
     *
     * @return mixed
     */
    public function update(User $user, Disease $disease)
    {
        return false;
    }

    /**
     * Determine whether the user can delete the model.
     *
     * @param \App\Models\User    $user
     * @param \App\Models\Disease $disease
     *
     * @return mixed
     */
    public function delete(User $user, Disease $disease)
    {
        return false;
    }

    /**
     * Determine whether the user can restore the model.
     *
     * @param \App\Models\User    $user
     * @param \App\Models\Disease $disease
     *
     * @return mixed
     */
    public function restore(User $user, Disease $disease)
    {
        return false;
    }

    /**
     * Determine whether the user can permanently delete the model.
     *
     * @param \App\Models\User    $user
     * @param \App\Models\Disease $disease
     *
     * @return mixed
     */
    public function forceDelete(User $user, Disease $disease)
    {
        return false;
    }
}
