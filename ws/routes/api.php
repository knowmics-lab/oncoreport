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
use Illuminate\Support\Facades\Route;

Route::get('/ping', [PingController::class, 'ping']);
Route::middleware('auth:sanctum')->get('/auth-ping', [PingController::class, 'ping']);

Route::apiResource('users', UserController::class)->names(
    [
        'show' => 'users.show',
    ]
)->middleware('auth:sanctum');

Route::middleware(
    [
        'auth:sanctum',
        'can:generate-token,user',
    ]
)->get('/users/{user}/token', [UserController::class, 'token']);

Route::middleware('auth:sanctum')->get('/user', [PingController::class, 'user']);

Route::apiResource('diseases', DiseaseController::class)->names(
    [
        'show' => 'diseases.show',
    ]
)->except(['create', 'store', 'update', 'destroy'])->middleware('auth:sanctum');

Route::apiResource('patients', PatientController::class)->names(
    [
        'show' => 'patients.show',
    ]
)->middleware('auth:sanctum');

Route::apiResource('jobs', JobController::class)->names(
    [
        'show' => 'jobs.show',
    ]
)->middleware('auth:sanctum');

Route::middleware(
    [
        'auth:sanctum',
        'can:submit-job,job',
    ]
)->get('/jobs/{job}/submit', [JobController::class, 'submit'])->name('jobs.submit');

Route::middleware(
    [
        'auth:sanctum',
        'can:view,patient',
        'can:viewAny,\\App\\Models\\Job',
    ]
)->get('/jobs/by_patient/{patient}', [JobController::class, 'byPatient'])->name('jobs.by.patient');

Route::middleware(
    [
        'auth:sanctum',
        'can:upload-job,job',
    ]
)->any('/jobs/{job}/upload/{any?}', [JobController::class, 'upload'])->where('any', '.*')->name('jobs.upload');

Route::middleware('auth:sanctum')->get('/job-types', [JobTypeController::class, 'index'])->name('job-types.index');
Route::middleware('auth:sanctum')->get('/job-types/{type}', [JobTypeController::class, 'show'])->name('job-types.show');


