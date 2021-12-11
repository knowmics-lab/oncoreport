<div>
    <x-slot name="header">
        <h2 class="font-semibold text-xl text-gray-800 leading-tight">
            {{ __('Create user') }}
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
                                    <x-jet-label for="role" value="{{ __('Role') }}"/>
                                    <select id="role" class="form-select px-4 py-3 rounded block mt-1 w-full"
                                            wire:model.defer="state.role" name="role">
                                        @foreach(\App\Constants::ROLES as $role)
                                            <option value="{{$role}}">
                                                {{ucfirst($role)}}
                                            </option>
                                        @endforeach
                                    </select>
                                </div>
                            </div>
                        </div>
                    </div>
                    <div class="flex items-center justify-end px-4 py-3 bg-gray-50 text-right sm:px-6">
                        <a href="{{ route('users-list') }}"
                           class="mr-3 inline-flex items-center px-4 py-2 bg-indigo-800 border border-transparent rounded-md font-semibold text-xs text-white uppercase tracking-widest hover:bg-indigo-700 active:bg-indigo-900 focus:outline-none focus:border-gray-900 focus:shadow-outline-indigo disabled:opacity-25 transition ease-in-out duration-150">
                            <i class="fas fa-arrow-left"></i>&nbsp;Go Back
                        </a>

                        <x-jet-button wire:loading.attr="disabled">
                            <i class="fas fa-save"></i>&nbsp;Create user
                        </x-jet-button>
                    </div>
                </div>
            </div>
        </div>
    </form>
</div>
