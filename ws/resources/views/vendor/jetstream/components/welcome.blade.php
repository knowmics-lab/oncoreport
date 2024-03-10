@props([
    'oncokbStatus' => false,
    'oncokbStatusMessage' => '',
])
@php
    $oncokbMessageColor = 'text-gray-500';
    if ($oncokbStatus === 'error') {
        $oncokbMessageColor = 'text-red-500';
    } elseif ($oncokbStatus === 'warning') {
        $oncokbMessageColor = 'text-orange-500';
    }
@endphp
<div class="p-6 sm:px-20 bg-white border-b border-gray-200">
    <div class="mt-8 text-2xl">
        Welcome to your Oncoreport Webservice instance!
    </div>

    <div class="mt-6 text-gray-500">
        From this page you will be able to manage your profile details and API keys.
        An API keys is required to enable the connection between the Oncoreport App and this instance.
        For more details please refer to the Oncoreport manual.
    </div>

    @if ($oncokbStatus)
        <div class="mt-6 {{ $oncokbMessageColor }} font-semibold">
            {{ $oncokbStatusMessage }}
        </div>
    @endif

    @if (config('oncoreport.config_generator'))
        <div class="mt-6 text-gray-500 text-center">
            <a href="{{ route('config-download') }}"
               class="mr-3 inline-flex items-center px-4 py-2 bg-indigo-800 border border-transparent rounded-md font-semibold text-xs text-white uppercase tracking-widest hover:bg-indigo-700 active:bg-indigo-900 focus:outline-none focus:border-gray-900 focus:shadow-outline-indigo disabled:opacity-25 transition ease-in-out duration-150">
                <i class="fas fa-download"></i>&nbsp;Download Client Config
            </a>
        </div>
    @endif
</div>
