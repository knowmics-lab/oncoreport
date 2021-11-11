<?php
/**
 * Oncoreport Web Service
 *
 * @author S. Alaimo, Ph.D. <alaimos at gmail dot com>
 */

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\DiseaseResource;
use App\Http\Services\BuilderRequestService;
use App\Models\Disease;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;

class DiseaseController extends Controller
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
        $this->tokenAuthorize($request, 'read', 'viewAny', Disease::class);

        return DiseaseResource::collection(
            $requestService->handleWithGlobalSearch(
                $request,
                Disease::query(),
                ['doid', 'name'],
                static function (Builder $builder, Request $request) {
                    if ($request->has('tumor')) {
                        $builder->where('tumor', $request->boolean('tumor'));
                    }
                },
                'name',
                'asc'
            )
        );
    }

    /**
     * Display the specified resource.
     *
     * @param  \Illuminate\Http\Request  $request
     * @param  \App\Models\Disease  $disease
     *
     * @return \App\Http\Resources\DiseaseResource
     * @throws \Illuminate\Auth\Access\AuthorizationException
     */
    public function show(Request $request, Disease $disease): DiseaseResource
    {
        $this->tokenAuthorize($request, 'read', 'view', $disease);

        return new DiseaseResource($disease);
    }

}
