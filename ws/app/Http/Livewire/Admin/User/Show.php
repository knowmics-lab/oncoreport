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
use Illuminate\Validation\Rule;
use Laravel\Fortify\Rules\Password;
use Livewire\Component;

class Show extends Component
{
    use AuthorizesRequests;

    public User $user;
    public array $state;

    /**
     * Get validation rules
     *
     * @return array
     */
    public function rules(): array
    {
        $uniqueRule = Rule::unique('users', 'email');
        if (isset($this->user)) {
            $uniqueRule = $uniqueRule->ignore($this->user->id);
        }

        return [
            'state.name'     => ['required', 'string', 'max:255'],
            'state.email'    => ['required', 'string', 'email', 'max:255', $uniqueRule],
            'state.password' => ['nullable', 'string', new Password()],
            'state.role'     => ['sometimes', Rule::in(Constants::ROLES)],
        ];
    }

    /**
     * Prepare the component.
     *
     * @param  \App\Models\User  $user
     *
     * @return void
     */
    public function mount(User $user): void
    {
        $this->user = $user;
        $this->state = $user->withoutRelations()->toArray();
    }

    /**
     * Handles form submission
     *
     * @throws \Illuminate\Auth\Access\AuthorizationException
     */
    public function submit(): void
    {
        $this->authorize('update', $this->user);
        $this->validate();
        if (isset($this->state['password']) && !empty($this->state['password'])) {
            $this->user->password = Hash::make($this->state['password']);
        }
        $this->user->update(
            [
                'name'  => $this->state['name'],
                'email' => $this->state['email'],
                'role'  => $this->state['role'],
            ]
        );
        $this->emit('saved');
        $this->emit('refresh-navigation-dropdown');
    }


    /**
     * Render this component
     *
     * @return \Illuminate\Contracts\View\View
     * @throws \Illuminate\Auth\Access\AuthorizationException
     */
    public function render(): View
    {
        $this->authorize('view', $this->user);

        return view('livewire.admin.user.show');
    }
}
