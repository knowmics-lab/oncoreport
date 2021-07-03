<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;

class PatientController extends Controller
{
    public function __construct()
    {
        $this->middleware('auth:patient');
    }

    public function index(){
        error_log('ciao ' . \Auth::guard('patient')->user()->first_name);
        return view('patient.dashboard');
    }
}
