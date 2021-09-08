<?php

namespace App\Http\Controllers;

use App\Http\Resources\Location as ResourcesLocation;
use App\Http\Resources\LocationCollection;
use App\Http\Resources\LocationResource;
use App\Models\Location;
use Illuminate\Http\Request;

class LocationController extends Controller
{
    public function index(Request $request){
        return new LocationCollection(Location::all());
    }
}
