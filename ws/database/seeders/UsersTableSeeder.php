<?php

namespace Database\Seeders;

use App\Constants;
use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

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
                'role'              => Constants::ADMIN,
            ]
        );
        if (config('app.debug')) {
            User::firstOrCreate(
                [
                    'email' => 'doctor@doctor',
                ],
                [
                    'name'              => 'doctor',
                    'email_verified_at' => now(),
                    'password'          => Hash::make('password'),
                    'role'              => Constants::DOCTOR,
                ]
            );
            User::firstOrCreate(
                [
                    'email' => 'technical@technical',
                ],
                [
                    'name'              => 'technical staff',
                    'email_verified_at' => now(),
                    'password'          => Hash::make('password'),
                    'role'              => Constants::TECHNICAL,
                ]
            );
        }
    }
}
