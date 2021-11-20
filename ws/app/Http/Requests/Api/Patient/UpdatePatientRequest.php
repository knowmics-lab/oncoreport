<?php

namespace App\Http\Requests\Api\Patient;

use App\Constants;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class UpdatePatientRequest extends FormRequest
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
            'code'                         => ['sometimes', 'required', 'string', 'alpha_dash', 'max:255'],
            'first_name'                   => ['sometimes', 'required', 'string', 'max:255'],
            'last_name'                    => ['sometimes', 'required', 'string', 'max:255'],
            'gender'                       => ['sometimes', 'required', 'string', Rule::in(Constants::GENDERS)],
            'age'                          => ['sometimes', 'required', 'integer', 'between:0,150'],
            'email'                        => ['sometimes', 'nullable', 'email'],
            'fiscal_number'                => ['sometimes', 'nullable', 'string', 'max:255'],
            'telephone'                    => ['sometimes', 'nullable', 'string', 'max:255'],
            'city'                         => ['sometimes', 'nullable', 'string', 'max:255'],
            'primary_disease'              => ['sometimes', 'required', 'array'],
            'primary_disease.id'           => [
                'sometimes',
                'required',
                Rule::exists('patient_diseases', 'id')->where('patient_id', $this->patient->id),
            ],
            'primary_disease.disease'      => [
                'sometimes',
                'required',
                Rule::exists('diseases', 'id')->where('tumor', 1),
            ],
            'primary_disease.type'         => ['sometimes', 'nullable', Rule::in(Constants::TUMOR_TYPES)],
            'primary_disease.T'            => ['sometimes', 'nullable', 'integer'],
            'primary_disease.N'            => ['sometimes', 'nullable', 'integer'],
            'primary_disease.M'            => ['sometimes', 'nullable', 'integer'],
            'primary_disease.start_date'   => ['sometimes', 'nullable', 'date'],
            'diseases'                     => ['sometimes', 'nullable', 'array'],
            'diseases.*.id'                => [
                'sometimes',
                'required',
                Rule::exists('patient_diseases', 'id')->where('patient_id', $this->patient->id),
            ],
            'diseases.*.disease'           => ['sometimes', 'required', Rule::exists('diseases', 'id')],
            'diseases.*.type'              => ['sometimes', 'nullable', Rule::in(Constants::TUMOR_TYPES)],
            'diseases.*.T'                 => ['sometimes', 'nullable', 'integer'],
            'diseases.*.N'                 => ['sometimes', 'nullable', 'integer'],
            'diseases.*.M'                 => ['sometimes', 'nullable', 'integer'],
            'diseases.*.start_date'        => ['sometimes', 'nullable', 'date'],
            'diseases.*.end_date'          => ['sometimes', 'nullable', 'date'],
            'drugs'                        => ['sometimes', 'nullable', 'array'],
            'drugs.*.id'                   => [
                'sometimes',
                'required',
                Rule::exists('patient_drugs', 'id')->where('patient_id', $this->patient->id),
            ],
            'drugs.*.drug'                 => ['sometimes', 'required', Rule::exists('drugs', 'id')],
            'drugs.*.disease'              => ['sometimes', 'nullable', 'integer'],
            'drugs.*.suspension_reasons'   => ['sometimes', 'nullable', 'array'],
            'drugs.*.suspension_reasons.*' => ['sometimes', 'integer', Rule::exists('suspension_reasons', 'id')],
            'drugs.*.comment'              => ['sometimes', 'nullable', 'string'],
            'drugs.*.start_date'           => ['sometimes', 'nullable', 'date'],
            'drugs.*.end_date'             => ['sometimes', 'nullable', 'date'],
            'deleted_diseases'             => ['sometimes', 'array'],
            'deleted_diseases.*'           => [
                'integer',
                Rule::exists('patient_diseases', 'id')->where('patient_id', $this->patient->id),
            ],
            'deleted_drugs'                => ['sometimes', 'array'],
            'deleted_drugs.*'              => [
                'integer',
                Rule::exists('patient_drugs', 'id')->where('patient_id', $this->patient->id),
            ],
        ];
    }
}
