<?php

namespace App\Providers;

use App\Models\Disease;
use App\Models\Job;
use App\Models\Patient;
use App\Models\User;
use App\Policies\DiseasePolicy;
use App\Policies\JobPolicy;
use App\Policies\PatientPolicy;
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
        User::class    => UserPolicy::class,
        Job::class     => JobPolicy::class,
        Patient::class => PatientPolicy::class,
        Disease::class => DiseasePolicy::class,
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
