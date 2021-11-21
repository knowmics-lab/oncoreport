<div>
    <x-slot name="header">
        <h2 class="font-semibold text-xl text-gray-800 leading-tight">
            {{ __('Manage Users') }}
        </h2>
    </x-slot>

    <div>
        @if (session()->has('message'))
            <div x-data="{ open: true }">
                <div x-show="open" class="bg-green-600">
                    <div class="max-w-screen-xl mx-auto py-3 px-3 sm:px-6 lg:px-8">
                        <div class="flex items-center justify-between flex-wrap">
                            <div class="w-0 flex-1 flex items-center">
                    <span class="flex p-2 rounded-lg bg-green-800 text-white">
                        <i class="fas fa-check"></i>
                    </span>
                                <p class="ml-3 font-medium text-white truncate">
                                    {{ session('message') }}
                                </p>
                            </div>
                            <div class="order-2 flex-shrink-0 sm:order-3 sm:ml-3">
                                <button @click="open = false" type="button"
                                        class="-mr-1 flex p-2 rounded-md hover:bg-green-500 focus:outline-none focus:bg-green-500 sm:-mr-2 transition ease-in-out duration-150"
                                        aria-label="Dismiss">
                                    <!-- Heroicon name: x -->
                                    <svg class="h-6 w-6 text-white" xmlns="http://www.w3.org/2000/svg" fill="none"
                                         viewBox="0 0 24 24" stroke="currentColor">
                                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                                              d="M6 18L18 6M6 6l12 12"/>
                                    </svg>
                                </button>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        @endif
    </div>

    <div class="py-12">
        <div class="max-w-7xl mx-auto sm:px-6 lg:px-8">
            <div class="bg-white overflow-hidden shadow-xl sm:rounded-lg">
                <div class="p-6 sm:px-20 bg-white border-b border-gray-200">

                    <div class="mt-8 flex flex-col">
                        <div class="-my-2 overflow-x-auto sm:-mx-6 lg:-mx-8">
                            <div class="py-2 align-middle inline-block min-w-full sm:px-6 lg:px-8">
                                <div class="shadow overflow-hidden border-b border-gray-200 sm:rounded-lg">
                                    <table class="min-w-full divide-y divide-gray-200">
                                        <thead>
                                            <tr>
                                                <th class="px-6 py-3 bg-gray-50 text-left text-xs leading-4 font-medium text-gray-500 uppercase tracking-wider">
                                                    Name
                                                </th>
                                                <th class="px-6 py-3 bg-gray-50 text-left text-xs leading-4 font-medium text-gray-500 uppercase tracking-wider">
                                                    E-mail
                                                </th>
                                                <th class="px-6 py-3 bg-gray-50 text-left text-xs leading-4 font-medium text-gray-500 uppercase tracking-wider">
                                                    Role
                                                </th>
                                                <th class="px-6 py-3 bg-gray-50"></th>
                                            </tr>
                                        </thead>
                                        <tbody class="bg-white divide-y divide-gray-200">
                                            @forelse($users as $user)
                                                <tr>
                                                    <td class="px-6 py-4 whitespace-no-wrap text-sm leading-5 text-gray-500">
                                                        {{ $user->name }}
                                                    </td>
                                                    <td class="px-6 py-4 whitespace-no-wrap">
                                                        {{ $user->email }}
                                                    </td>
                                                    <td class="px-6 py-4 whitespace-no-wrap text-sm leading-5 text-gray-500">
                                                        {{ ucfirst($user->role) }}
                                                    </td>
                                                    <td class="px-6 py-4 whitespace-no-wrap text-right text-sm leading-5 font-medium">
                                                        <a href="{{ route('users-show', $user) }}"
                                                           class="text-indigo-600 hover:text-indigo-900 mr-3">
                                                            <i class="fas fa-user-edit"></i>
                                                            Edit
                                                        </a>
                                                        @if ($user->id !== auth()->id())
                                                            <a href="Javascript:"
                                                               wire:click="delete({{ $user->id }})"
                                                               class="text-red-600 hover:text-red-900">
                                                                <i class="fas fa-user-minus"></i>
                                                                Delete
                                                            </a>
                                                        @endif
                                                    </td>
                                                </tr>
                                            @empty
                                                <tr>
                                                    <td class="px-6 py-4 whitespace-no-wrap text-sm leading-5 text-gray-500"
                                                        colspan="3">
                                                        No users found.
                                                    </td>
                                                </tr>
                                            @endforelse
                                        </tbody>
                                    </table>
                                </div>
                            </div>
                        </div>
                    </div>
                    <div class="mt-6 mb-8 text-gray-500">
                        {{ $users->links() }}
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>
