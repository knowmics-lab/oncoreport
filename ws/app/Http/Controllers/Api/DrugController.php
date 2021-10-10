<?php
/**
 * Oncoreport Web Service
 *
 * @author S. Alaimo, Ph.D. <alaimos at gmail dot com>
 */

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\DrugResource;
use App\Http\Services\BuilderRequestService;
use App\Models\Drug;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;

class DrugController extends Controller
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
        $this->tokenAuthorize($request, 'read', 'viewAny', Drug::class);

        return DrugResource::collection(
            $requestService->handleWithGlobalSearch(
                $request,
                Drug::query(),
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
     * @param  \App\Models\Drug  $drug
     *
     * @return \App\Http\Resources\DrugResource
     * @throws \Illuminate\Auth\Access\AuthorizationException
     */
    public function show(Request $request, Drug $drug): DrugResource
    {
        $this->tokenAuthorize($request, 'read', 'view', $drug);

        return new DrugResource($drug);
    }

}
