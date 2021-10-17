<?php

namespace App\Http\Resources;

use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin \App\Models\PatientDrug
 * @package App\Http\Resources
 */
class PatientDrugResource extends JsonResource
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
            'id'                 => $this->id,
            'patient_id'         => $this->patient_id,
            'patient'            => new PatientResource($this->whenLoaded('patient')),
            'disease_id'         => $this->patient_disease_id,
            'disease'            => new PatientDiseaseResource($this->whenLoaded('disease')),
            'drug'               => new DrugResource($this->whenLoaded('drug')),
            'suspension_reasons' => SuspensionReasonResource::collection($this->whenLoaded('suspensionReasons')),
            'start_date'         => $this->start_date->toDateString(),
            'end_date'           => is_null($this->end_date) ?: $this->end_date->toDateString(),
            'comment'            => $this->comment,
            'created_at'         => $this->created_at,
            'created_at_diff'    => $this->created_at->diffForHumans(),
            'updated_at'         => $this->updated_at,
            'updated_at_diff'    => $this->updated_at->diffForHumans(),
        ];
    }
}
