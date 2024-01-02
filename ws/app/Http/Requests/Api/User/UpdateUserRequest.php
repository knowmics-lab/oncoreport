<?php

namespace App\Http\Requests\Api\User;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;
use Illuminate\Validation\Rules\Password;

class UpdateUserRequest extends FormRequest
{
    /**
     * Determine if the user is authorized to make this request.
     *
     * @return bool
     */
    public function authorize(): bool
    {
        return true;
    }

    /**
     * Get the validation rules that apply to the request.
     *
     * @return array
     */
    public function rules(): array
    {
        $rules = [
            'name'         => ['filled', 'string', 'max:255'],
            'email'        => [
                'filled',
                'string',
                'email',
                'max:255',
                Rule::unique('users', 'email')->ignore($this->user),
            ],
            'password'     => ['required_with_all:new_password', 'password'],
            'new_password' => ['filled', Password::default()],
            'role'         => ['filled', Rule::in(config('constants.roles'))],
        ];
        if ($this->user()->is_admin) {
            unset($rules['password']);
        } else {
            unset($rules['role']);
        }

        return $rules;
    }
}
