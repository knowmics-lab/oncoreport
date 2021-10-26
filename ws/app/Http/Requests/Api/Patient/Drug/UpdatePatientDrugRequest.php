<?php

namespace App\Http\Requests\Api\Patient\Drug;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class UpdatePatientDrugRequest extends FormRequest
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
            'drug'                 => ['sometimes', 'required', Rule::exists('drugs', 'id')],
            'disease'              => ['sometimes', 'nullable', Rule::exists('diseases', 'id')],
            'disease_id'           => ['sometimes', 'nullable', Rule::exists('diseases', 'id')],
            'suspension_reasons'   => ['sometimes', 'nullable', 'array'],
            'suspension_reasons.*' => ['sometimes', 'integer', Rule::exists('suspension_reasons', 'id')],
            'comment'              => ['sometimes', 'nullable', 'string'],
            'start_date'           => ['sometimes', 'nullable', 'date'],
            'end_date'             => ['sometimes', 'nullable', 'date'],
        ];
    }
}
