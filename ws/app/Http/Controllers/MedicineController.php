<?php

namespace App\Http\Controllers;

use App\Http\Resources\MedicineCollection;
use App\Models\Medicine;
use Illuminate\Http\Request;

class MedicineController extends Controller
{
    public function index(){
        return new MedicineCollection(Medicine::all());
    }
}
