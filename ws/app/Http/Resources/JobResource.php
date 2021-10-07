<?php
/**
 * Oncoreport Web Service
 *
 * @author S. Alaimo, Ph.D. <alaimos at gmail dot com>
 */

namespace App\Http\Resources;

use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin \App\Models\Job
 * @package App\Http\Resources
 */
class JobResource extends JsonResource
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
            'id'              => $this->id,
            'sample_code'     => $this->sample_code,
            'name'            => $this->name,
            'type'            => $this->job_type,
            'readable_type'   => $this->resource->readableJobType(),
            'status'          => $this->status,
            'parameters'      => $this->job_parameters,
            'output'          => $this->job_output,
            'log'             => $this->log,
            'created_at'      => $this->created_at,
            'created_at_diff' => $this->created_at->diffForHumans(),
            'updated_at'      => $this->updated_at,
            'updated_at_diff' => $this->updated_at->diffForHumans(),
            'owner'           => new UserResource($this->whenLoaded('owner')),
            'patient'         => new PatientResource($this->whenLoaded('patient')),
        ];
    }
}
