<?php
/**
 * Oncoreport Web Service
 *
 * @author S. Alaimo, Ph.D. <alaimos at gmail dot com>
 */

namespace App\Http\Livewire\Admin\User;

use App\Models\User;
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
            'state.admin'    => ['sometimes', 'boolean'],
            'state.role'     => ['sometimes', Rule::in(config('constants.roles'))],
        ];
    }

    /**
     * Prepare the component.
     *
     * @param \App\Models\User $user
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
        $this->user->name = $this->state['name'];
        $this->user->email = $this->state['email'];
        $this->user->admin = $this->state['admin'];
        if (isset($this->state['password']) && !empty($this->state['password'])) {
            $this->user->password = Hash::make($this->state['password']);
        }
        $this->user->role = $this->state['role'];
        $this->user->save();
        $this->emit('saved');
        $this->emit('refresh-navigation-dropdown');
    }


    /**
     * Render this component
     *
     * @return \Illuminate\Contracts\Foundation\Application|\Illuminate\Contracts\View\Factory|\Illuminate\Contracts\View\View
     * @throws \Illuminate\Auth\Access\AuthorizationException
     */
    public function render()
    {
        $this->authorize('view', $this->user);

        return view('livewire.admin.user.show');
    }
}
