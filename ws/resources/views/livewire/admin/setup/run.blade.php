<div>
    <x-slot name="header">
        <h2 class="font-semibold text-xl text-gray-800 leading-tight">
            @if (is_null($setupJob))
                {{ __('Setup script') }}
            @else
                {{ __('Running setup script') }}
            @endif
        </h2>
    </x-slot>

    @if (is_null($setupJob))
        <form wire:submit.prevent="submit">
            <div class="py-12">
                <div class="max-w-7xl mx-auto sm:px-6 lg:px-8">
                    <div class="bg-white overflow-hidden shadow-2xl sm:rounded-lg">
                        <div class="p-6 sm:px-20 bg-white border-b border-gray-200">
                            <div class="mt-8 mb-8">
                                <div class="grid grid-cols-6 gap-6">
                                    <div class="col-span-6">
                                        <x-jet-label for="name" value="{{ __('Cosmic Username') }}"/>
                                        <x-jet-input id="name" type="text" class="mt-1 block w-full"
                                                     wire:model.defer="cosmicUsername" autocomplete="cosmicUsername"/>
                                        <x-jet-input-error for="cosmicUsername" class="mt-2"/>
                                    </div>
                                    <div class="col-span-6">
                                        <x-jet-label for="password" value="{{ __('Cosmic Password') }}"/>
                                        <x-jet-input id="password" type="password" class="mt-1 block w-full"
                                                     wire:model.defer="cosmicPassword" autocomplete="cosmicPassword"/>
                                        <x-jet-input-error for="cosmicPassword" class="mt-2"/>
                                    </div>
                                </div>
                            </div>
                        </div>
                        <div class="flex items-center justify-end px-4 py-3 bg-gray-50 text-right sm:px-6">
                            @if ($jobError)
                                <div x-data="{ shown: false, timeout: null }"
                                     x-init="clearTimeout(timeout); shown = true; timeout = setTimeout(() => { shown = false }, 2000);"
                                     x-show.transition.opacity.out.duration.1500ms="shown"
                                     style="display: none;"
                                     class="text-sm mr-3 text-red-600">
                                    {{ __('An error occurred. Please try again!') }}
                                </div>
                            @endif

                            <x-jet-button wire:loading.attr="disabled">
                                <i class="fas fa-save"></i>&nbsp;Run Setup
                            </x-jet-button>
                        </div>
                    </div>
                </div>
            </div>
        </form>
    @else
        <div class="py-12">
            <div class="max-w-7xl mx-auto sm:px-6 lg:px-8">
                <div class="bg-white overflow-hidden shadow-2xl rounded-lg">
                    <div class="p-6 sm:px-20 bg-gray-800 border-b border-gray-200">
                        <div class="flex items-center justify-end px-4 py-3 bg-gray-800 text-right sm:px-6">
                            @if ($setupJob->status === \App\Constants::COMPLETED)
                                <x-jet-button wire:loading.attr="disabled" wire:click.prevent="done"
                                              class="bg-green-600">
                                    <i class="fas fa-check"></i>&nbsp;Click to Finish
                                </x-jet-button>
                            @endif
                        </div>
                        <div class="mt-4 mb-4 relative">
                            @if ($setupJob->status !== \App\Constants::COMPLETED)
                                <div class="flex items-center justify-center sticky top-0">
                                    <div class="w-10 h-10 border-b-2 border-white rounded-full animate-spin"></div>
                                </div>
                            @endif
                            <div class="w-100 h-auto rounded-lg overflow-auto">
                                @if ($setupJob->status === \App\Constants::COMPLETED)
                                    <pre class="py-4 px-4 mt-1 text-white text-xl">{{ $setupJob->log === '' ? 'Please wait...' : $setupJob->log }}</pre>
                                @else
                                    <pre class="py-4 px-4 mt-1 text-white text-xl"
                                         wire:poll.2000ms="refresh">{{ $setupJob->log === '' ? 'Please wait...' : $setupJob->log }}</pre>
                                @endif
                            </div>
                        </div>
                        <div class="flex items-center justify-end px-4 py-3 bg-gray-800 text-right sm:px-6">
                            @if ($setupJob->status === \App\Constants::COMPLETED)
                                <x-jet-button wire:loading.attr="disabled" wire:click.prevent="done"
                                              class="bg-green-600">
                                    <i class="fas fa-check"></i>&nbsp;Click to Finish
                                </x-jet-button>
                            @endif
                        </div>
                    </div>
                </div>
            </div>
        </div>
    @endif
</div>
