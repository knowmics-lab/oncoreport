<?php

use App\Http\Controllers\ClientConfigController;
use App\Http\Controllers\DashboardController;
use App\Http\Livewire\Admin\Setup\Run as AdminRunSetup;
use App\Http\Livewire\Admin\User\Create as AdminUserCreate;
use App\Http\Livewire\Admin\User\Index as AdminUserIndex;
use App\Http\Livewire\Admin\User\Show as AdminUserShow;
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

Route::get('/', static fn() => redirect()->route('dashboard'));

Route::group(
    [
        'middleware' => [
            'auth',
            'verified',
        ],
    ],
    static function () {
        Route::get('/dashboard', DashboardController::class)->name('dashboard');
        Route::get('/admin/users', AdminUserIndex::class)
             ->name('users-list')
             ->middleware('can:view-any,App\Models\User');
        Route::get('/admin/users/create', AdminUserCreate::class)
             ->name('users-create')
             ->middleware('can:create,App\Models\User');
        Route::get('/admin/users/{user}', AdminUserShow::class)
             ->name('users-show');
        if (config('oncoreport.cloud_env')) {
            Route::get('/admin/setup', AdminRunSetup::class)
                 ->name('run-setup');
        }
        if (config('oncoreport.config_generator')) {
            Route::get('/config-download', ClientConfigController::class)->name('config-download');
        }
    }
);

