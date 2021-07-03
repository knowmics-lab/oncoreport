<?php

namespace App\Http\Resources;

use Illuminate\Http\Resources\Json\JsonResource;

class Pathology extends JsonResource
{
    /**
     * Transform the resource into an array.
     *
     * @param  \Illuminate\Http\Request  $request
     * @return array
     */
    public function toArray($request)
    {
        if(isset($this->pivot))
            return [
                'id'              => $this->id,
                'name'            => $this->name,
                'medicines' => new MedicineCollection($this->pivot->medicines),
            ];
        return parent::toArray($request);
    }
}
