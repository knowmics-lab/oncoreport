<?php
/**
 * Oncoreport Web Service
 *
 * @author S. Alaimo, Ph.D. <alaimos at gmail dot com>
 */

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Jobs\Types\Factory;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class JobTypeController extends Controller
{
    /**
     * Display a listing of the resource.
     *
     * @param \Illuminate\Http\Request $request
     *
     * @return \Illuminate\Http\JsonResponse
     */
    public function index(Request $request): JsonResponse
    {
        abort_unless($request->user()->tokenCan('read'), 403, 'User token is not allowed to read objects');

        return response()->json(
            [
                'data'  => Factory::listTypes()->keyBy('id'),
            ]
        );
    }

    /**
     * Display the specified resource.
     *
     * @param \Illuminate\Http\Request $request
     * @param string                   $type
     *
     * @return \Illuminate\Http\JsonResponse
     */
    public function show(Request $request, string $type): JsonResponse
    {
        abort_unless($request->user()->tokenCan('read'), 403, 'User token is not allowed to read objects');
        $types = Factory::listTypes();
        $res = $types->where('id', '=', $type)->first();
        if (!$res) {
            abort(404, 'No query results for type ' . $type);
        }
        $id = $res['id'];
        $res['parameters'] = Factory::parametersSpec($id);
        $res['output'] = Factory::outputSpec($id);

        return response()->json(
            [
                'data'  => $res,
                'links' => [
                    'self' => route('job-types.show', $id, false),
                ],
            ]
        );
    }

}
