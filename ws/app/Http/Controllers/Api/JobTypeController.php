<?php
/**
 * Oncoreport Web Service
 *
 * @author S. Alaimo, Ph.D. <alaimos at gmail dot com>
 */

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Jobs\Types\Factory;
use F9Web\ApiResponseHelpers;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class JobTypeController extends Controller
{
    use ApiResponseHelpers;

    /**
     * Display a listing of the resource.
     *
     * @param  \Illuminate\Http\Request  $request
     *
     * @return \Illuminate\Http\JsonResponse
     * @throws \Illuminate\Auth\Access\AuthorizationException
     */
    public function index(Request $request): JsonResponse
    {
        $this->tokenAuthorize($request, 'read');

        return $this->respondWithSuccess(
            [
                'data' => Factory::listTypes(),
            ]
        );
    }

    /**
     * Display the specified resource.
     *
     * @param  \Illuminate\Http\Request  $request
     * @param  string  $type
     *
     * @return \Illuminate\Http\JsonResponse
     * @throws \Illuminate\Auth\Access\AuthorizationException
     */
    public function show(Request $request, string $type): JsonResponse
    {
        $this->tokenAuthorize($request, 'read');
        $types = Factory::listTypes();
        $res = $types->where('id', $type)->firstOrFail();
        $id = $res['id'];
        $res['parameters'] = Factory::parametersSpec($id);
        $res['output'] = Factory::outputSpec($id);

        return $this->respondWithSuccess(
            [
                'data' => $res,
            ]
        );
    }

}
