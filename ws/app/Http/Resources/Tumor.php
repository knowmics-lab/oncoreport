<?php

namespace App\Http\Resources;

use Illuminate\Http\Resources\Json\JsonResource;

class Tumor extends JsonResource
{
    /**
     * Transform the resource into an array.
     *
     * @param  \Illuminate\Http\Request  $request
     * @return array
     */
    public function toArray($request)
    {
        if (isset($this->pivot))
            return [
                'id' => $this->id,
                'name' => $this->name,
                'type' => $this->pivot->type,
                'sede' => "sede 1",
                'association_id' => $this->pivot->id,
                'stadio' => [
                    'T' => $this->pivot->T,
                    'N' => $this->pivot->N,
                    'M' => $this->pivot->M,
                ],
                'drugs' => new DrugCollection($this->pivot->drugs)
            ];
        return [
            'id' => $this->id,
            'name' => $this->name
        ];
    }
}
