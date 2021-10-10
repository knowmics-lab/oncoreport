<?php
/**
 * Oncoreport Web Service
 *
 * @author S. Alaimo, Ph.D. <alaimos at gmail dot com>
 */

namespace App\Http\Controllers\Api;

use App\Actions\Api\User\CreateUser;
use App\Actions\Api\User\CreateUserToken;
use App\Actions\Api\User\UpdateUser;
use App\Actions\Jetstream\DeleteUser;
use App\Http\Controllers\Controller;
use App\Http\Requests\Api\User\StoreUserRequest;
use App\Http\Requests\Api\User\UpdateUserRequest;
use App\Http\Resources\UserResource;
use App\Http\Services\BuilderRequestService;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;

class UserController extends Controller
{

    /**
     * Display a listing of the resource.
     *
     * @param  \Illuminate\Http\Request  $request
     * @param  \App\Http\Services\BuilderRequestService  $requestService
     *
     * @return \Illuminate\Http\Resources\Json\AnonymousResourceCollection
     * @throws \Illuminate\Auth\Access\AuthorizationException
     */
    public function index(Request $request, BuilderRequestService $requestService): AnonymousResourceCollection
    {
        $this->tokenAuthorize($request, 'read', 'viewAny', User::class);

        return UserResource::collection($requestService->handle($request, User::query()));
    }

    /**
     * Store a newly created resource in storage.
     *
     * @param  \App\Http\Requests\Api\User\StoreUserRequest  $request
     * @param  \App\Actions\Api\User\CreateUser  $createAction
     *
     * @return object
     * @throws \Illuminate\Auth\Access\AuthorizationException
     */
    public function store(StoreUserRequest $request, CreateUser $createAction): object
    {
        $this->tokenAuthorize($request, ['read', 'create'], 'create', User::class);

        return
            (new UserResource($createAction->create($request->validated())))
                ->toResponse($request)
                ->setStatusCode(201);
    }

    /**
     * Display the specified resource.
     *
     * @param  \Illuminate\Http\Request  $request
     * @param  \App\Models\User  $user
     *
     * @return \App\Http\Resources\UserResource
     * @throws \Illuminate\Auth\Access\AuthorizationException
     */
    public function show(Request $request, User $user): UserResource
    {
        $this->tokenAuthorize($request, 'read', 'create', User::class);

        return new UserResource($user);
    }

    /**
     * Update the specified resource in storage.
     *
     * @param  \App\Http\Requests\Api\User\UpdateUserRequest  $request
     * @param  \App\Models\User  $user
     * @param  \App\Actions\Api\User\UpdateUser  $updateAction
     *
     * @return \App\Http\Resources\UserResource
     * @throws \Illuminate\Auth\Access\AuthorizationException
     */
    public function update(UpdateUserRequest $request, User $user, UpdateUser $updateAction): UserResource
    {
        $this->tokenAuthorize($request, ['read', 'update'], 'update', $user);

        return new UserResource($updateAction->update($user, $request->validated()));
    }

    /**
     * Remove the specified resource from storage.
     *
     * @param  \Illuminate\Http\Request  $request
     * @param  \App\Models\User  $user
     * @param  \App\Actions\Jetstream\DeleteUser  $deleteUserAction
     *
     * @return \Illuminate\Http\JsonResponse
     * @throws \Illuminate\Auth\Access\AuthorizationException
     */
    public function destroy(Request $request, User $user, DeleteUser $deleteUserAction): JsonResponse
    {
        $this->tokenAuthorize($request, ['read', 'delete'], 'delete', $user);
        $deleteUserAction->delete($user);

        return response()->json(['ok' => true]);
    }

    /**
     * Make a new token for the user
     *
     * @param  \Illuminate\Http\Request  $request
     * @param  \App\Models\User  $user
     * @param  \App\Actions\Api\User\CreateUserToken  $createTokenAction
     *
     * @return \Illuminate\Http\JsonResponse
     * @throws \Illuminate\Auth\Access\AuthorizationException
     */
    public function token(Request $request, User $user, CreateUserToken $createTokenAction): JsonResponse
    {
        $this->tokenAuthorize($request, ['read', 'update'], 'generateToken', $user);
        $token = $createTokenAction->create($user);

        return response()->json(
            [
                'data' => [
                    'id' => $user->id,
                    'api_token' => $token->plainTextToken,
                ],
            ]
        );
    }
}
