<?php

namespace App\Http\Controllers;

use App\Http\Resources\LocationCollection;
use App\Models\Location;

class LocationController extends Controller
{
    public function index(): LocationCollection
    {
        return new LocationCollection(Location::all());
    }
}
