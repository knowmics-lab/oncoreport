<?php

namespace App\Http\Requests\Api\Patient\Disease;

use App\Constants;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;
use Laravel\Fortify\Rules\Password;

class StorePatientDiseaseRequest extends FormRequest
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
            'disease'    => ['required', Rule::exists('diseases', 'id')],
            'location'   => ['nullable', Rule::exists('locations', 'id')],
            'type'       => ['nullable', Rule::in(Constants::TUMOR_TYPES)],
            'T'          => ['nullable', 'integer'],
            'N'          => ['nullable', 'integer'],
            'M'          => ['nullable', 'integer'],
            'start_date' => ['nullable', 'date'],
            'end_date'   => ['nullable', 'date'],
        ];
    }
}
