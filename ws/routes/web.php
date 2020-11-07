<?php

use App\Http\Livewire\Admin\User\Index as UserIndex;
use App\Http\Livewire\Admin\User\Create as UserCreate;
use App\Http\Livewire\Admin\User\Show as UserShow;
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

Route::get(
    '/',
    function () {
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
