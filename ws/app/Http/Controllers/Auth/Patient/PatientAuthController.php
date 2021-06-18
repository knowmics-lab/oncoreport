<?php

namespace App\Http\Controllers\Auth\Patient;

use App\Http\Controllers\Controller;
use App\Models\Patient;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class PatientAuthController extends Controller
{
    protected $redirectTo = '/patient/home';
    public function __construct()
    {
        $this->middleware('guest:patient')->except('logout');
    }

    public function showLoginForm()
    {
        return view('auth.patient.login');
    }

    public function username()
    {
        return 'email';
    }

    public function guard()
    {
        return \Auth::guest('patient');
    }




    public function login(Request $request){

        $credentials = $request->validate([
            'email' => ['required', 'email'],
            'password' => ['required'],
        ]);



        if (Auth::guard('patient')->attempt($credentials)) {
            $request->session()->regenerate();
            return redirect()->intended('patient.home');
        }

        return back()->withErrors([
            'email' => 'The provided credentials do not match our records.',
        ]);
        return json_encode($credentials);
    }

    public function logout(Request $request){
        Auth::guard('patient')->logout();
        $request->session()->invalidate();

        $request->session()->regenerateToken();

        return redirect('/patient/home');
    }

}
