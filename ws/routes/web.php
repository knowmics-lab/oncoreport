<?php

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
        return view('welcome');
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
    'UserController@index'
)->name('users-list')->middleware('can:view-any,App\\Models\\User');
Route::middleware(['auth:sanctum', 'verified'])->get(
    '/admin/users/new',
    'UserController@create'
)->name('users-create')->middleware('can:create,App\\Models\\User');
Route::middleware(['auth:sanctum', 'verified'])->post(
    '/admin/users/new',
    'UserController@doCreate'
)->name('users-do-create')->middleware('can:create,App\\Models\\User');
Route::middleware(['auth:sanctum', 'verified'])->get(
    '/admin/users/{user}',
    'UserController@show'
)->name('users-show')->middleware('can:view,user');
Route::middleware(['auth:sanctum', 'verified'])->post(
    '/admin/users/{user}',
    'UserController@update'
)->name('users-update')->middleware('can:update,user');
Route::middleware(['auth:sanctum', 'verified'])->get(
    '/admin/users/{user}/delete',
    'UserController@delete'
)->name('users-delete')->middleware('can:delete,user');
