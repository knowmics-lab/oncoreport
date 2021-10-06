<?php

namespace App\Http\Controllers;

use App\Http\Resources\MedicineCollection;
use App\Models\Medicine;

class MedicineController extends Controller
{
    public function index(): MedicineCollection
    {
        return new MedicineCollection(Medicine::all());
    }
}
