<?php
/**
 * Oncoreport Web Service
 *
 * @author S. Alaimo, Ph.D. <alaimos at gmail dot com>
 */

namespace App\Http\Resources;

use Illuminate\Http\Resources\Json\ResourceCollection;

class JobCollection extends ResourceCollection
{

    /**
     * Transform the resource collection into an array.
     *
     * @param \Illuminate\Http\Request $request
     *
     * @return array
     */
    public function toArray($request)
    {
        return $this->collection->map(
            static function (Job $item) use ($request) {
                $tmp = $item->toArray($request);
                $data = $tmp['data'];
                unset($data['parameters'], $data['log']);
                $data['self.link'] = $tmp['links']['self'];
                $data['owner.link'] = $tmp['links']['owner'];
                $data['patient.link'] = $tmp['links']['patient'];
                $data['upload.link'] = $tmp['links']['upload'];
                $data['submit.link'] = $tmp['links']['submit'];

                return $data;
            }
        )->all();
    }
}
