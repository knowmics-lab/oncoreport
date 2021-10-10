<?php

namespace App\Actions\Api\User;

use App\Models\User;
use Hash;
use Illuminate\Support\Str;

class CreateUser
{

    public function create(array $values): User
    {
        return User::create(
            [
                'name'              => $values['name'],
                'email'             => $values['email'],
                'email_verified_at' => now(),
                'password'          => Hash::make($values['password']),
                'remember_token'    => Str::random(10),
                'role'              => $values['role'],
            ]
        );
    }

}