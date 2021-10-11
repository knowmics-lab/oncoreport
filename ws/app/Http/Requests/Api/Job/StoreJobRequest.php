<?php

namespace App\Http\Requests\Api\Job;

use App\Jobs\Types\Factory;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class StoreJobRequest extends FormRequest
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
        $jobTypes = Factory::listTypes();

        return [
            'sample_code' => ['required', 'string', 'alpha_dash'],
            'name'        => ['required', 'string'],
            'type'        => ['required', 'string', Rule::in($jobTypes->pluck('id'))],
            'parameters'  => ['filled', 'array'],
        ];
    }
}
