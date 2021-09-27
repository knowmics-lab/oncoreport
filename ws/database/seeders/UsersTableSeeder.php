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
        User::firstOrCreate(
            [
                'email' => 'admin@admin',
            ],
            [
                'name'              => 'admin',
                'email_verified_at' => now(),
                'password'          => Hash::make('password'),
                'remember_token'    => Str::random(10),
                'admin'             => true,
            ]
        );
        User::firstOrCreate(
            [
                'email' => 'user@user',
            ],
            [
                'name'              => 'user',
                'email_verified_at' => now(),
                'password'          => Hash::make('password'),
                'remember_token'    => Str::random(10),
                'admin'             => false,
            ]
        );
    }
}
