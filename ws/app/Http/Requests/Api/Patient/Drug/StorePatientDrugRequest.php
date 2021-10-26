<?php

namespace App\Http\Requests\Api\Patient\Drug;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class StorePatientDrugRequest extends FormRequest
{
    /**
     * Determine if the user is authorized to make this request.
     *
     * @return bool
     */
    public function authorize(): bool
    {
        return true;
    }

    /**
     * Get the validation rules that apply to the request.
     *
     * @return array
     */
    public function rules(): array
    {
        return [
            'drug'                 => ['required', Rule::exists('drugs', 'id')],
            'disease'              => ['nullable', Rule::exists('diseases', 'id')],
            'disease_id'           => ['nullable', Rule::exists('diseases', 'id')],
            'suspension_reasons'   => ['nullable', 'array'],
            'suspension_reasons.*' => ['integer', Rule::exists('suspension_reasons', 'id')],
            'comment'              => ['nullable', 'string'],
            'start_date'           => ['nullable', 'date'],
            'end_date'             => ['nullable', 'date'],
        ];
    }
}
