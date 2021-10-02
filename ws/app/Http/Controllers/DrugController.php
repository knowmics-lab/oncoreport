<?php

namespace App\Http\Controllers;

use App\Http\Resources\DrugCollection;
use App\Models\Drug;

class DrugController extends Controller
{
    public function index(): DrugCollection
    {
        return new DrugCollection(Drug::all());
    }
}
