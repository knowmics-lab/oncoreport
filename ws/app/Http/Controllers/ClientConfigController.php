<?php

namespace App\Http\Controllers;

use App\Actions\Api\User\CreateUserToken;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ClientConfigController extends Controller
{
    /**
     * Handle the incoming request.
     *
     * @param  \Illuminate\Http\Request  $request
     * @param  \App\Actions\Api\User\CreateUserToken  $createTokenAction
     *
     * @return \Illuminate\Http\JsonResponse
     */
    public function __invoke(Request $request, CreateUserToken $createTokenAction): JsonResponse
    {
        $token = $createTokenAction->create($request->user(), 'config-generator-token-');

        $displayedToken = explode('|', $token->plainTextToken, 2)[1];

        return response()->json([
            'apiProtocol' => $request->getScheme(),
            'apiHostname' => $request->getHost(),
            'apiPort'     => $request->getPort(),
            'apiPath'     => '/api/',
            'publicPath'  => '/storage/',
            'apiKey'      => $displayedToken,
        ], 200, [
            'Content-type'        => 'application/json',
            'Content-Disposition' => sprintf('attachment; filename="oncoreport-%s.json"', now()->format('YmdHis')),
        ]);
    }
}
