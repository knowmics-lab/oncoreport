<?php
/**
 * Oncoreport Web Service
 *
 * @author S. Alaimo, Ph.D. <alaimos at gmail dot com>
 */

namespace App\Http\Resources;

use Illuminate\Http\Resources\Json\JsonResource;

/**
 * Class User
 * @mixin \App\Models\User
 * @package App\Http\Resources
 */
class User extends JsonResource
{
    /**
     * Transform the resource into an array.
     *
     * @param \Illuminate\Http\Request $request
     *
     * @return array
     */
    public function toArray($request): array
    {
        $data = [
            'id'              => $this->id,
            'name'            => $this->name,
            'email'           => $this->email,
            'admin'           => $this->admin,
            'role'            => $this->role,
            'created_at'      => $this->created_at,
            'created_at_diff' => $this->created_at->diffForHumans(),
            'updated_at'      => $this->updated_at,
            'updated_at_diff' => $this->updated_at->diffForHumans(),
        ];
        if (!$request->user()->admin) {
            unset($data['admin']);
        }

        return [
            'data'  => $data,
            'links' => [
                'self' => route('users.show', $this->resource, false),
            ],
        ];
    }
}
