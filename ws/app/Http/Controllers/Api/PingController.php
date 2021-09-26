<?php
/**
 * Oncoreport Web Service
 *
 * @author S. Alaimo, Ph.D. <alaimos at gmail dot com>
 */

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class PingController extends Controller
{
    /**
     * @return \Illuminate\Http\JsonResponse
     */
    public function ping(): JsonResponse
    {
        return response()->json(
            [
                'data' => 'pong',
            ]
        );
    }

    /**
     * @param  \Illuminate\Http\Request  $request
     *
     * @return mixed
     * @throws \Illuminate\Auth\Access\AuthorizationException
     */
    public function user(Request $request)
    {
        $this->authorize('view', $request->user());
        abort_unless($request->user()->tokenCan('read'), 403, 'User token is not allowed to read objects');

        return $request->user();
    }
}
