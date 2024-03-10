<?php

namespace App\Http\Controllers;

use App\Http\Services\SystemInfoService;
use Illuminate\Http\Request;
use Illuminate\View\View;

class DashboardController extends Controller
{
    /**
     * Handle the incoming request.
     *
     * @param  \Illuminate\Http\Request  $request
     *
     * @return \Illuminate\View\View
     */
    public function __invoke(Request $request, SystemInfoService $sysInfo): View
    {
        $oncokbStatus = $sysInfo->oncokbTokenStatus();

        return view(
            'dashboard',
            [
                'oncokbStatus'        => $oncokbStatus['status'],
                'oncokbStatusMessage' => $oncokbStatus['message'],
            ]
        );
    }
}
