<?php

namespace App\Providers;

use App\Models\Disease;
use App\Models\Drug;
use App\Models\Job;
use App\Models\Location;
use App\Models\Patient;
use App\Models\SuspensionReason;
use App\Models\User;
use App\Policies\JobPolicy;
use App\Policies\PatientPolicy;
use App\Policies\ResourcePolicy;
use App\Policies\UserPolicy;
use Illuminate\Foundation\Support\Providers\AuthServiceProvider as ServiceProvider;

class AuthServiceProvider extends ServiceProvider
{
    /**
     * The policy mappings for the application.
     *
     * @var array
     */
    protected $policies = [
        Disease::class          => ResourcePolicy::class,
        Drug::class             => ResourcePolicy::class,
        Job::class              => JobPolicy::class,
        Location::class         => ResourcePolicy::class,
        Patient::class          => PatientPolicy::class,
        SuspensionReason::class => ResourcePolicy::class,
        User::class             => UserPolicy::class,
    ];

    /**
     * Register any authentication / authorization services.
     *
     * @return void
     */
    public function boot(): void
    {
        $this->registerPolicies();
        //
    }
}
