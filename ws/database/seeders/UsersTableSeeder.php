<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;

class UsersTableSeeder extends Seeder
{
    /**
     * Run the database seeds.
     *
     * @return void
     */
    public function run(): void
    {
        User::create(
            [
                'name'              => 'admin',
                'email'             => 'admin@admin',
                'email_verified_at' => now(),
                'password'          => Hash::make('password'),
                'remember_token'    => Str::random(10),
                'admin'             => true,
            ]
        )->save();
        User::create(
            [
                'name'              => 'user',
                'email'             => 'user@user',
                'email_verified_at' => now(),
                'password'          => Hash::make('password'),
                'remember_token'    => Str::random(10),
                'admin'             => false,
            ]
        )->save();
    }
}
