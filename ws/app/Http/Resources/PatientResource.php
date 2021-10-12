<?php
/**
 * Oncoreport Web Service
 *
 * @author S. Alaimo, Ph.D. <alaimos at gmail dot com>
 */

namespace App\Http\Resources;

use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin \App\Models\Patient
 * @package App\Http\Resources
 */
class PatientResource extends JsonResource
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
            'code'            => $this->code,
            'first_name'      => $this->first_name,
            'last_name'       => $this->last_name,
            'age'             => $this->age,
            'gender'          => $this->gender,
            'email'           => $this->email,
            'fiscal_number'   => $this->fiscal_number,
            'telephone'       => $this->telephone ?? '',
            'city'            => $this->city ?? '',
            'diseases'        => PatientDiseaseResource::collection($this->whenLoaded('diseases')),
            'primary_disease' => new PatientDiseaseResource($this->whenLoaded('primaryDisease')),
            'drugs'           => PatientDrugResource::collection($this->whenLoaded('drugs')),
            'user'            => new UserResource($this->whenLoaded('user')),
            'owner'           => new UserResource($this->whenLoaded('owner')),
            'created_at'      => $this->created_at,
            'created_at_diff' => $this->created_at->diffForHumans(),
            'updated_at'      => $this->updated_at,
            'updated_at_diff' => $this->updated_at->diffForHumans(),
        ];
    }
}
