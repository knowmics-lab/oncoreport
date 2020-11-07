<?php
/**
 * Oncoreport Web Service
 *
 * @author S. Alaimo, Ph.D. <alaimos at gmail dot com>
 */

namespace App\Http\Resources;

use Illuminate\Http\Resources\Json\ResourceCollection;

class PatientCollection extends ResourceCollection
{

    /**
     * Indicates if the resource's collection keys should be preserved.
     *
     * @var bool
     */
    public $preserveKeys = true;

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
            static function (Patient $item) use ($request) {
                $tmp = $item->toArray($request);
                $data = $tmp['data'];
                $data['self.link'] = $tmp['links']['self'];
                $data['owner.link'] = $tmp['links']['owner'];
                $data['jobs.link'] = $tmp['links']['jobs'];

                return $data;
            }
        )->keyBy('id')->all();
    }
}
