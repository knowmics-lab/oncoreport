<?php
/**
 * Oncoreport Web Service
 *
 * @author S. Alaimo, Ph.D. <alaimos at gmail dot com>
 */

namespace App\Http\Resources;

use App\Utils;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * Class User
 * @mixin \App\Models\Patient
 * @package App\Http\Resources
 */
class Patient extends JsonResource
{
    /**
     * Transform the resource into an array.
     *
     * @param  \Illuminate\Http\Request  $request
     *
     * @return array
     */
    public function toArray($request): array
    {
        return [
            'data'  => [
                'id'              => $this->id,
                'code'            => $this->code,
                'first_name'      => $this->first_name,
                'last_name'       => $this->last_name,
                'age'             => $this->age,
                'gender'          => $this->gender,
                'email'           => $this->email,
                'fiscalNumber'    => $this->fiscal_number,
                'disease'         => Utils::flattenResource(new Disease($this->disease), $request),
                'owner'           => $this->user ? Utils::flattenResource(new User($this->user), $request) : null,
                'created_at'      => $this->created_at,
                'created_at_diff' => $this->created_at->diffForHumans(),
                'updated_at'      => $this->updated_at,
                'updated_at_diff' => $this->updated_at->diffForHumans(),
                'tumors'          => new TumorCollection($this->tumors),
                'diseases'        => new PathologyCollection($this->diseases),
                'drugs'           => $this->drugs()->get(),
            ],
            'links' => [
                'self'  => route('patients.show', $this->resource, false),
                'owner' => $this->user ? route('users.show', $this->user, false) : null,
                'jobs'  => route('jobs.by.patient', $this->id, false),
            ],
        ];
    }
}
