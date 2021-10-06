<?php

namespace App\Http\Controllers;

use App\Http\Resources\Tumor as TumorResource;
use App\Http\Resources\TumorCollection;
use App\Models\Tumor;

class TumorController extends Controller
{

    public function index(): TumorCollection
    {
        return new TumorCollection(Tumor::all());
    }

    public function show(Tumor $tumor): TumorResource
    {
        return new TumorResource($tumor);
    }
}
