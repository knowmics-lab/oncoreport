<?php

namespace App\Actions\Api\User;

use App\Models\User;
use Illuminate\Support\Str;
use Laravel\Sanctum\NewAccessToken;

class CreateUserToken
{

    public function create(User $user): NewAccessToken
    {
        $key = Str::random(5);

        return $user->createToken(
            'api-call-token-' . $key,
            [
                'create',
                'read',
                'update',
                'delete',
            ]
        );
    }

}