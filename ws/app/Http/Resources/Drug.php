<?php

namespace App\Http\Resources;

use Illuminate\Http\Resources\Json\JsonResource;

class Drug extends JsonResource
{
    /**
     * Transform the resource into an array.
     *
     * @param  \Illuminate\Http\Request  $request
     * @return array
     */
    public function toArray($request)
    {

        return
        $this->pivot ?
        [
            'id' => $this->id,
            'name' => $this->name,
            'start_date' => $this->pivot->start_date,
            'end_date' => $this->pivot->end_date,
            'reasons' => $this->pivot->reasons,
        ] :
        [
            'id' => $this->id,
            'name' => $this->name
        ];
    }
}
