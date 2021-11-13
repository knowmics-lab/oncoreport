<?php
/**
 * Oncoreport Web Service
 *
 * @author S. Alaimo, Ph.D. <alaimos at gmail dot com>
 */

namespace App\Http\Resources;

use Illuminate\Http\Resources\Json\JsonResource;
use JetBrains\PhpStorm\ArrayShape;

/**
 * @mixin \App\Models\Disease
 * @package App\Http\Resources
 */
class DiseaseResource extends JsonResource
{
    /**
     * Transform the resource into an array.
     *
     * @param  \Illuminate\Http\Request  $request
     *
     * @return array
     */
    #[ArrayShape([
        'id'              => "int",
        'doid'            => "string",
        'name'            => "string",
        'tumor'           => "bool",
        'created_at'      => "\Illuminate\Support\Carbon|null",
        'created_at_diff' => "string",
        'updated_at'      => "\Illuminate\Support\Carbon|null",
        'updated_at_diff' => "string",
    ])] public function toArray($request): array
    {
        return [
            'id'              => $this->id,
            'doid'            => $this->doid,
            'name'            => $this->name,
            'tumor'           => $this->tumor,
            'created_at'      => $this->created_at,
            'created_at_diff' => $this->created_at->diffForHumans(),
            'updated_at'      => $this->updated_at,
            'updated_at_diff' => $this->updated_at->diffForHumans(),
        ];
    }
}
