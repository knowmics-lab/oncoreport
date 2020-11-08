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
 * Class Job
 * @mixin \App\Models\Job
 * @package App\Http\Resources
 */
class Job extends JsonResource
{
    /**
     * Transform the resource into an array.
     *
     * @param \Illuminate\Http\Request $request
     *
     * @return array
     */
    public function toArray($request)
    {
        return [
            'data'  => [
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
                'owner'           => Utils::flattenResource(new User($this->user), $request),
                'patient'         => $this->patient ? Utils::flattenResource(new Patient($this->patient), $request) : null,
            ],
            'links' => [
                'self'    => route('jobs.show', $this->resource, false),
                'owner'   => route('users.show', $this->user, false),
                'patient' => $this->patient ? route('patients.show', $this->patient, false) : null,
                'upload'  => route('jobs.upload', $this->resource, false),
                'submit'  => route('jobs.submit', $this->resource, false),
            ],
        ];
    }
}
