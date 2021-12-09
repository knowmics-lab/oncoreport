<?php
/**
 * Oncoreport Web Service
 *
 * @author S. Alaimo, Ph.D. <alaimos at gmail dot com>
 */

namespace App\Http\Livewire\Admin\User;

use App\Constants;
use App\Models\User;
use Illuminate\Contracts\View\View;
use Illuminate\Foundation\Auth\Access\AuthorizesRequests;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;
use Illuminate\Validation\Rule;
use Laravel\Fortify\Rules\Password;
use Livewire\Component;

class Create extends Component
{

    use AuthorizesRequests;

    public array $state = [
        'name'     => '',
        'email'    => '',
        'password' => '',
        'role'     => Constants::DOCTOR,
    ];

    /**
     * Get validation rules
     *
     * @return array
     */
    public function rules(): array
    {
        return [
            'state.name'     => ['required', 'string', 'max:255'],
            'state.email'    => ['required', 'string', 'email', 'max:255', Rule::unique('users', 'email')],
            'state.password' => ['nullable', 'string', new Password()],
            'state.role'     => ['sometimes', Rule::in(Constants::ROLES)],
        ];
    }

    /**
     * Handles form submission
     *
     * @return mixed
     * @throws \Illuminate\Auth\Access\AuthorizationException
     */
    public function submit(): mixed
    {
        $this->authorize('create', User::class);
        $this->validate();
        User::create(
            [
                'name'              => $this->state['name'],
                'email'             => $this->state['email'],
                'email_verified_at' => now(),
                'password'          => Hash::make($this->state['password']),
                'remember_token'    => Str::random(10),
                'role'              => $this->state['role'],
            ]
        )->save();
        $this->emit('refresh-navigation-dropdown');
        session()->flash('message', 'User successfully created.');

        return redirect()->route('users-list');
    }


    /**
     * Renders this component
     *
     * @return \Illuminate\Contracts\View\View
     * @throws \Illuminate\Auth\Access\AuthorizationException
     */
    public function render(): View
    {
        $this->authorize('create', User::class);

        return view('livewire.admin.user.create');
    }
}
