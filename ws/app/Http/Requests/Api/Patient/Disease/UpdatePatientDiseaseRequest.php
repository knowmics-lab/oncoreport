<?php

namespace App\Http\Requests\Api\Patient\Disease;

use App\Constants;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class UpdatePatientDiseaseRequest extends FormRequest
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
            'disease'    => ['sometimes', 'required', Rule::exists('diseases', 'id')],
            'location'   => ['sometimes', 'nullable', Rule::exists('locations', 'id')],
            'type'       => ['sometimes', 'nullable', Rule::in(Constants::TUMOR_TYPES)],
            'T'          => ['sometimes', 'nullable', 'integer'],
            'N'          => ['sometimes', 'nullable', 'integer'],
            'M'          => ['sometimes', 'nullable', 'integer'],
            'start_date' => ['sometimes', 'nullable', 'date'],
            'end_date'   => ['sometimes', 'nullable', 'date'],
        ];
    }
}
