<?php
/**
 * Oncoreport Web Service
 *
 * @author S. Alaimo, Ph.D. <alaimos at gmail dot com>
 */

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\Disease as DiseaseResource;
use App\Http\Resources\DiseaseCollection;
use App\Jobs\Types\Factory;
use App\Models\Disease;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class DiseaseController extends Controller
{

    /**
     * Display a listing of the resource.
     *
     * @param \Illuminate\Http\Request $request
     *
     * @return \App\Http\Resources\DiseaseCollection
     * @throws \Illuminate\Auth\Access\AuthorizationException
     */
    public function index(Request $request): DiseaseCollection
    {
        $this->authorize('viewAny', Disease::class);
        abort_unless($request->user()->tokenCan('read'), 403, 'User token is not allowed to read objects');

        return new DiseaseCollection(Disease::all());
    }

    /**
     * Display the specified resource.
     *
     * @param \Illuminate\Http\Request $request
     * @param \App\Models\Disease      $disease
     *
     * @return \App\Http\Resources\Disease
     * @throws \Illuminate\Auth\Access\AuthorizationException
     */
    public function show(Request $request, Disease $disease): DiseaseResource
    {
        $this->authorize('view', $disease);
        abort_unless($request->user()->tokenCan('read'), 403, 'User token is not allowed to read objects');

        return new DiseaseResource($disease);
    }

}
