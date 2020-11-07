<?php
/**
 * Oncoreport Web Service
 *
 * @author S. Alaimo, Ph.D. <alaimos at gmail dot com>
 */

namespace App\Http\Resources;

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
     * @param \Illuminate\Http\Request $request
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
                'disease'         => new Disease($this->disease),
                'owner'           => $this->user ? new User($this->user) : null,
                'created_at'      => $this->created_at,
                'created_at_diff' => $this->created_at->diffForHumans(),
                'updated_at'      => $this->updated_at,
                'updated_at_diff' => $this->updated_at->diffForHumans(),
            ],
            'links' => [
                'self'  => route('patients.show', $this->resource),
                'owner' => $this->user ? route('users.show', $this->user) : null,
                'jobs'  => route('jobs.by.patient', $this->id),
            ],
        ];
    }
}
