<?php
/**
 * Oncoreport Web Service
 *
 * @author S. Alaimo, Ph.D. <alaimos at gmail dot com>
 */

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\LocationResource;
use App\Http\Services\BuilderRequestService;
use App\Models\Location;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;

class LocationController extends Controller
{

    /**
     * Display a listing of the resource.
     *
     * @param  \Illuminate\Http\Request  $request
     * @param  \App\Http\Services\BuilderRequestService  $requestService
     *
     * @return \Illuminate\Http\Resources\Json\AnonymousResourceCollection
     * @throws \Illuminate\Auth\Access\AuthorizationException
     */
    public function index(Request $request, BuilderRequestService $requestService): AnonymousResourceCollection
    {
        $this->tokenAuthorize($request, 'read', 'viewAny', Location::class);

        return LocationResource::collection(
            $requestService->handleWithGlobalSearch(
                $request,
                Location::query(),
                ['name'],
                defaultOrderField: 'name',
                defaultOrdering: 'asc',
                paginate: false
            )
        );
    }

    /**
     * Display the specified resource.
     *
     * @param  \Illuminate\Http\Request  $request
     * @param  \App\Models\Location  $location
     *
     * @return \App\Http\Resources\LocationResource
     * @throws \Illuminate\Auth\Access\AuthorizationException
     */
    public function show(Request $request, Location $location): LocationResource
    {
        $this->tokenAuthorize($request, 'read', 'view', $location);

        return new LocationResource($location);
    }

}
