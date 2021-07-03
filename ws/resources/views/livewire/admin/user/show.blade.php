<div>
    <x-slot name="header">
        <h2 class="font-semibold text-xl text-gray-800 leading-tight">
            {{ __('Edit user') }}
        </h2>
    </x-slot>

    <form wire:submit.prevent="submit">
        <div class="py-12">
            <div class="max-w-7xl mx-auto sm:px-6 lg:px-8">
                <div class="bg-white overflow-hidden shadow-xl sm:rounded-lg">
                    <div class="p-6 sm:px-20 bg-white border-b border-gray-200">
                        <div class="mt-8 mb-8">
                            <div class="grid grid-cols-6 gap-6">
                                <div class="col-span-6">
                                    <x-jet-label for="name" value="{{ __('Name') }}"/>
                                    <x-jet-input id="name" type="text" class="mt-1 block w-full"
                                                 wire:model.defer="state.name" autocomplete="name"/>
                                    <x-jet-input-error for="state.name" class="mt-2"/>
                                </div>

                                <div class="col-span-6">
                                    <x-jet-label for="email" value="{{ __('Email') }}"/>
                                    <x-jet-input id="email" type="text" class="mt-1 block w-full"
                                                 wire:model.defer="state.email" autocomplete="name"/>
                                    <x-jet-input-error for="state.email" class="mt-2"/>
                                </div>
                                <!-- role -->
                                <div class="col-span-6">
                                    <x-jet-label for="role" value="{{ __('Role') }}"/>
                                    <x-jet-input id="role" type="text" class="mt-1 block w-full"
                                                 wire:model.defer="state.role" autocomplete="role"/>
                                    <x-jet-input-error for="state.role" class="mt-2"/>
                                </div>
                                <div class="col-span-6">
                                    <x-jet-label for="password" value="{{ __('Password') }}"/>
                                    <x-jet-input id="password" type="password" class="mt-1 block w-full"
                                                 wire:model.defer="state.password" autocomplete="password"/>
                                    <p class="mt-2 text-sm text-gray-500">
                                        If empty password will not be changed
                                    </p>
                                    <x-jet-input-error for="state.password" class="mt-2"/>
                                </div>
                                <div class="col-span-6">
                                    <div class="flex items-start">
                                        <div class="flex items-center h-5">
                                            <x-jet-input id="admin" type="checkbox"
                                                         class="form-checkbox h-4 w-4 text-indigo-600 transition duration-150 ease-in-out"
                                                         wire:model.defer="state.admin"/>
                                        </div>
                                        <div class="ml-3 text-sm leading-5">
                                            <x-jet-label for="admin" value="{{ __('Is admin?') }}"/>
                                            <p class="text-gray-500">Makes the user a system administrator.</p>
                                            <x-jet-input-error for="state.admin" class="mt-2"/>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                    <div class="flex items-center justify-end px-4 py-3 bg-gray-50 text-right sm:px-6">
                        <x-jet-action-message class="mr-3 text-green-600" on="saved">
                            {{ __('User has been updated.') }}
                        </x-jet-action-message>

                        <a href="{{ route('users-list') }}"
                           class="mr-3 inline-flex items-center px-4 py-2 bg-indigo-800 border border-transparent rounded-md font-semibold text-xs text-white uppercase tracking-widest hover:bg-indigo-700 active:bg-indigo-900 focus:outline-none focus:border-gray-900 focus:shadow-outline-indigo disabled:opacity-25 transition ease-in-out duration-150">
                            <i class="fas fa-arrow-left"></i>&nbsp;Go Back

                        </a>

                        <x-jet-button wire:loading.attr="disabled">
                            <i class="fas fa-save"></i>&nbsp;Edit user
                        </x-jet-button>
                    </div>
                </div>
            </div>
        </div>
    </form>
</div>
