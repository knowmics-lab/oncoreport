<?php

namespace App\Actions\Api\User;

use App\Models\User;
use Hash;

class UpdateUser
{

    public function update(User $user, array $values): User
    {
        if (isset($values['new_password'])) {
            $values['password'] = Hash::make($values['new_password']);
            unset($values['new_password']);
        }
        if (isset($values['role']) && !request()?->user()->is_admin) {
            unset($values['role']);
        }
        $user->update($values);

        return $user;
    }

}