<?php
/**
 * Oncoreport Web Service
 *
 * @author S. Alaimo, Ph.D. <alaimos at gmail dot com>
 */

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\SuspensionReasonResource;
use App\Http\Services\BuilderRequestService;
use App\Models\SuspensionReason;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;

class SuspensionReasonController extends Controller
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
        $this->tokenAuthorize($request, 'read', 'viewAny', SuspensionReason::class);

        return SuspensionReasonResource::collection(
            $requestService->handleWithGlobalSearch(
                $request,
                SuspensionReason::query(),
                ['name'],
                defaultOrderField: 'name',
                defaultOrdering: 'asc'
            )
        );
    }

    /**
     * Display the specified resource.
     *
     * @param  \Illuminate\Http\Request  $request
     * @param  \App\Models\SuspensionReason  $suspensionReason
     *
     * @return \App\Http\Resources\SuspensionReasonResource
     * @throws \Illuminate\Auth\Access\AuthorizationException
     */
    public function show(Request $request, SuspensionReason $suspensionReason): SuspensionReasonResource
    {
        $this->tokenAuthorize($request, 'read', 'view', $suspensionReason);

        return new SuspensionReasonResource($suspensionReason);
    }

}
