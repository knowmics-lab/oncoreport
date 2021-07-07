<?php

use App\Http\Livewire\Admin\User\Index as UserIndex;
use App\Http\Livewire\Admin\User\Create as UserCreate;
use App\Http\Livewire\Admin\User\Show as UserShow;
//use App\Http\Resources\Patient as PatientResource;
//use App\Http\Resources\PatientCollection;
//use App\Models\Patient;
use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| Web Routes
|--------------------------------------------------------------------------
|
| Here is where you can register web routes for your application. These
| routes are loaded by the RouteServiceProvider within a group which
| contains the "web" middleware group. Now create something great!
|
*/

Route::get( '/',
    function (Request $request) {
        //return new PatientResource(Patient::find(1));
        return redirect()->route('dashboard');
    }
);


Route::middleware(['auth:sanctum', 'verified'])->get(
    '/dashboard',
    function () {
        return view('dashboard');
    }
)->name('dashboard');

Route::middleware(['auth:sanctum', 'verified'])->get(
    '/admin/users',
    UserIndex::class
)->name('users-list')->middleware('can:view-any,App\\Models\\User');
Route::middleware(['auth:sanctum', 'verified'])->get(
    '/admin/users/create',
    UserCreate::class
)->name('users-create')->middleware('can:create,App\\Models\\User');
Route::middleware(['auth:sanctum', 'verified'])->get(
    '/admin/users/{user}',
    UserShow::class
)->name('users-show');

/*
Route::prefix('patient')
    ->as('patient.')
    ->group(function() {
        Route::get('home', '\App\Http\Controllers\PatientController@index')->name('home');
        Route::namespace('\App\Http\Controllers\Auth\Patient')
            ->group(function() {
                Route::get('login', 'PatientAuthController@showLoginForm')->name('login');
                Route::post('login', 'PatientAuthController@login')->name('login');
                Route::post('logout', 'PatientAuthController@logout')->name('logout');
            });
    });
*/
