<?php
/**
 * Oncoreport Web Service
 *
 * @author S. Alaimo, Ph.D. <alaimos at gmail dot com>
 */

use App\Http\Controllers\Api\DiseaseController;
use App\Http\Controllers\Api\JobController;
use App\Http\Controllers\Api\JobTypeController;
use App\Http\Controllers\Api\PatientController;
use App\Http\Controllers\Api\PingController;
use App\Http\Controllers\Api\UserController;
use App\Http\Controllers\DrugController;
use App\Http\Controllers\LocationController;
use App\Http\Controllers\MedicineController;
use App\Http\Controllers\PatientTumorController;
use App\Http\Controllers\TumorController;
use App\Http\Resources\MedicineCollection;
use App\Models\Reason;
use Illuminate\Support\Facades\Route;

Route::get('/ping', [PingController::class, 'ping']);
Route::apiResource('tumors', TumorController::class)->except(['create', 'store', 'update', 'destroy']);
Route::apiResource('drugs', DrugController::class)->except(['show', 'create', 'store', 'update', 'destroy']);
Route::apiResource('medicines', MedicineController::class)->except(['show', 'create', 'store', 'update', 'destroy']);
Route::apiResource('locations', LocationController::class)->except(['show', 'create', 'store', 'update', 'destroy']);
Route::get('reasons', fn() => new MedicineCollection(Reason::all()));

Route::group(
    [
        'middleware' => 'auth:sanctum',
    ],
    static function () {
        Route::get('/auth-ping', [PingController::class, 'ping']);
        Route::apiResource('users', UserController::class)->names(['show' => 'users.show']);
        Route::middleware('can:generate-token,user')->get('/users/{user}/token', [UserController::class, 'token']);
        Route::get('/user', [PingController::class, 'user']);
        Route::apiResource('diseases', DiseaseController::class)
             ->names(['show' => 'diseases.show'])
             ->except(['create', 'store', 'update', 'destroy']);
        Route::apiResource('patients', PatientController::class)
             ->names(['show' => 'patients.show']);
        Route::post('detach/{patient_id}/{tumor_id}/{drug_id}', [PatientTumorController::class, 'detach']);
        Route::post('detach/{patient_id}/{drug_id}', [PatientTumorController::class, 'detachAll']);
        Route::apiResource('jobs', JobController::class)->names(['show' => 'jobs.show']);
        Route::get('/jobs/{job}/submit', [JobController::class, 'submit'])
             ->middleware('can:submit-job,job')
             ->name('jobs.submit');
        Route::get('/jobs/by_patient/{patient}', [JobController::class, 'byPatient'])
             ->middleware(
                 [
                     'can:view,patient',
                     'can:viewAny,\\App\\Models\\Job',
                 ]
             )
             ->name('jobs.by.patient');
        Route::any('/jobs/{job}/upload/{any?}', [JobController::class, 'upload'])
             ->middleware('can:upload-job,job')
             ->where('any', '.*')
             ->name('jobs.upload');
        Route::get('/job-types', [JobTypeController::class, 'index'])->name('job-types.index');
        Route::get('/job-types/{type}', [JobTypeController::class, 'show'])->name('job-types.show');
    }
);
