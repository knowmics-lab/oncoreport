<?php

namespace App\Http\Controllers;

use App\Http\Resources\Tumor as ResourcesTumor;
use App\Http\Resources\TumorCollection;
use App\Models\Tumor;
use Illuminate\Http\Request;

class TumorController extends Controller
{

    public function index(Request $request)
    {
        #error_log('tumors requested');
        return new TumorCollection(Tumor::all());
    }

    public function show(Request $request, Tumor $tumor)
    {
        return new ResourcesTumor($tumor);
    }
}
