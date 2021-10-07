<?php

namespace App\Http\Resources;

use Illuminate\Http\Resources\Json\JsonResource;
use JetBrains\PhpStorm\ArrayShape;

class SuspensionReasonResource extends JsonResource
{
    /**
     * Transform the resource into an array.
     *
     * @param  \Illuminate\Http\Request  $request
     *
     * @return array
     */
    #[ArrayShape([
        'id'              => "mixed",
        'name'            => "mixed",
        'created_at'      => "mixed",
        'created_at_diff' => "mixed",
        'updated_at'      => "mixed",
        'updated_at_diff' => "mixed",
    ])] public function toArray($request): array
    {
        return [
            'id'              => $this->id,
            'name'            => $this->name,
            'created_at'      => $this->created_at,
            'created_at_diff' => $this->created_at->diffForHumans(),
            'updated_at'      => $this->updated_at,
            'updated_at_diff' => $this->updated_at->diffForHumans(),
        ];
    }
}
