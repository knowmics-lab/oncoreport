@props(['disabled' => false])

<input
    {{ $disabled ? 'disabled' : '' }}
    {!! $attributes->merge([
        'class' => ($attributes->get('type')==="checkbox" ? '': 'form-input rounded-md shadow-sm')
    ]) !!}>
