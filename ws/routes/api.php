<?php
/**
 * Oncoreport Web Service
 *
 * @author S. Alaimo, Ph.D. <alaimos at gmail dot com>
 */

use App\Http\Controllers\Api\DiseaseController;
use App\Http\Controllers\Api\DrugController;
use App\Http\Controllers\Api\JobController;
use App\Http\Controllers\Api\JobTypeController;
use App\Http\Controllers\Api\LocationController;
use App\Http\Controllers\Api\PatientController;
use App\Http\Controllers\Api\PatientDiseaseController;
use App\Http\Controllers\Api\PatientDiseaseDrugController;
use App\Http\Controllers\Api\PatientDrugController;
use App\Http\Controllers\Api\PingController;
use App\Http\Controllers\Api\SuspensionReasonController;
use App\Http\Controllers\Api\UserController;
use Illuminate\Support\Facades\Route;

Route::get('/ping', [PingController::class, 'ping']);

Route::group(
    [
        'middleware' => 'auth:sanctum',
    ],
    static function () {
        Route::get('/auth-ping', [PingController::class, 'ping']);
        Route::get('/sys-info', [PingController::class, 'sysInfo']);

        Route::apiResource('diseases', DiseaseController::class)->only(['index', 'show']);
        Route::apiResource('drugs', DrugController::class)->only(['index', 'show']);
        Route::apiResource('locations', LocationController::class)->only(['index', 'show']);
        Route::apiResource('suspension_reasons', SuspensionReasonController::class)->only(['index', 'show']);

        Route::patch('/jobs/{job}/submit', [JobController::class, 'submit'])
             ->middleware('can:submit,job')
             ->name('jobs.submit');
        Route::any('/jobs/{job}/upload/{any?}', [JobController::class, 'upload'])
             ->middleware('can:upload,job')
             ->where('any', '.*');
        Route::apiResource('jobs', JobController::class);
        Route::get('/job-types', [JobTypeController::class, 'index'])->name('job-types.index');
        Route::get('/job-types/{type}', [JobTypeController::class, 'show'])->name('job-types.show');

        Route::apiResource('patients', PatientController::class);
        Route::apiResource('patients.diseases', PatientDiseaseController::class);
        Route::apiResource('patients.diseases.drugs', PatientDiseaseDrugController::class);
        Route::apiResource('patients.drugs', PatientDrugController::class);

        Route::get('/user', [PingController::class, 'user']);
        Route::get('/users/{user}/token', [UserController::class, 'token'])
             ->middleware('can:generate-token,user');
        Route::apiResource('users', UserController::class);
    }
);
