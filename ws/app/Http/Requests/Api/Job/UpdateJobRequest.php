<?php

namespace App\Http\Requests\Api\Job;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class UpdateJobRequest extends FormRequest
{
    /**
     * Determine if the user is authorized to make this request.
     *
     * @return bool
     */
    public function authorize()
    {
        return true;
    }

    /**
     * Get the validation rules that apply to the request.
     *
     * @return array
     */
    public function rules()
    {
        return [
            'sample_code' => ['filled', 'string', 'alpha_dash'],
            'name'        => ['filled', 'string'],
            'parameters'  => ['filled', 'array'],
            'patient_id'  => ['nullable', 'integer', Rule::exists('patients', 'id')],
        ];
    }
}
