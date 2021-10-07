<?php

namespace App\Http\Resources;

use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin \App\Models\PatientDisease
 * @package App\Http\Resources
 */
class PatientDiseaseResource extends JsonResource
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
            'patient'         => new PatientResource($this->whenLoaded('patient')),
            'disease'         => new DiseaseResource($this->whenLoaded('disease')),
            'location'        => new LocationResource($this->whenLoaded('location')),
            'type'            => $this->type,
            'T'               => $this->T,
            'N'               => $this->N,
            'M'               => $this->M,
            'start_date'      => $this->start_date->toDateString(),
            'end_date'        => is_null($this->end_date) ?: $this->end_date->toDateString(),
            'created_at'      => $this->created_at,
            'created_at_diff' => $this->created_at->diffForHumans(),
            'updated_at'      => $this->updated_at,
            'updated_at_diff' => $this->updated_at->diffForHumans(),
        ];
    }
}
