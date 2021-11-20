<?php

namespace App\Http\Requests\Api\Patient;

use App\Constants;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;
use Laravel\Fortify\Rules\Password;

class StorePatientRequest extends FormRequest
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
            'code'                         => ['required', 'string', 'alpha_dash', 'max:255'],
            'first_name'                   => ['required', 'string', 'max:255'],
            'last_name'                    => ['required', 'string', 'max:255'],
            'gender'                       => ['required', 'string', Rule::in(Constants::GENDERS)],
            'age'                          => ['required', 'integer', 'between:0,150'],
            'create_account'               => ['nullable', 'boolean'],
            'email'                        => ['required_if:create_account,true', 'email'],
            'password'                     => ['required_if:create_account,true', 'string', new Password()],
            'fiscal_number'                => ['nullable', 'string', 'max:255'],
            'telephone'                    => ['nullable', 'string', 'max:255'],
            'city'                         => ['nullable', 'string', 'max:255'],
            'primary_disease'              => ['required', 'array'],
            'primary_disease.disease'      => ['required', Rule::exists('diseases', 'id')->where('tumor', 1)],
            'primary_disease.type'         => ['nullable', Rule::in(Constants::TUMOR_TYPES)],
            'primary_disease.T'            => ['nullable', 'integer'],
            'primary_disease.N'            => ['nullable', 'integer'],
            'primary_disease.M'            => ['nullable', 'integer'],
            'primary_disease.start_date'   => ['nullable', 'date'],
            'diseases'                     => ['nullable', 'array'],
            'diseases.*.disease'           => ['required', Rule::exists('diseases', 'id')],
            'diseases.*.type'              => ['nullable', Rule::in(Constants::TUMOR_TYPES)],
            'diseases.*.T'                 => ['nullable', 'integer'],
            'diseases.*.N'                 => ['nullable', 'integer'],
            'diseases.*.M'                 => ['nullable', 'integer'],
            'diseases.*.start_date'        => ['nullable', 'date'],
            'diseases.*.end_date'          => ['nullable', 'date'],
            'drugs'                        => ['nullable', 'array'],
            'drugs.*.drug'                 => ['required', Rule::exists('drugs', 'id')],
            'drugs.*.disease'              => ['nullable', 'integer'],
            'drugs.*.suspension_reasons'   => ['nullable', 'array'],
            'drugs.*.suspension_reasons.*' => ['integer', Rule::exists('suspension_reasons', 'id')],
            'drugs.*.comment'              => ['nullable', 'string'],
            'drugs.*.start_date'           => ['nullable', 'date'],
            'drugs.*.end_date'             => ['nullable', 'date'],
        ];
    }
}
