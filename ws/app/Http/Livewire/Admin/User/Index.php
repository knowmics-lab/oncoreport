<?php
/**
 * Oncoreport Web Service
 *
 * @author S. Alaimo, Ph.D. <alaimos at gmail dot com>
 */

namespace App\Http\Livewire\Admin\User;

use App\Models\User;
use Illuminate\Contracts\View\View;
use Illuminate\Foundation\Auth\Access\AuthorizesRequests;
use Livewire\Component;
use Livewire\WithPagination;

class Index extends Component
{
    use AuthorizesRequests;
    use WithPagination;

    /**
     * @param  \App\Models\User  $user
     *
     * @throws \Illuminate\Auth\Access\AuthorizationException
     */
    public function delete(User $user): void
    {
        if ($user->id === auth()->id()) {
            return;
        }
        $this->authorize('delete', $user);
        $user->deleteProfilePhoto();
        $user->tokens->each->delete();
        $user->delete();
    }

    /**
     *
     * @return \Illuminate\Contracts\View\View
     * @throws \Illuminate\Auth\Access\AuthorizationException
     */
    public function render(): View
    {
        $this->authorize('viewAny', User::class);

        return view(
            'livewire.admin.user.index',
            [
                'users' => User::paginate(20),
            ]
        );
    }
}
