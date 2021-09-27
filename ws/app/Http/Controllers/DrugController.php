<?php

namespace App\Http\Controllers;

use App\Http\Resources\DrugCollection;
use App\Models\Drug;
use Illuminate\Http\Request;

class DrugController extends Controller
{
    public function index(Request $reques)
    {
        return new DrugCollection(Drug::all());
    }
}
