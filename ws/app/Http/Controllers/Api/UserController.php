<?php
/**
 * Oncoreport Web Service
 *
 * @author S. Alaimo, Ph.D. <alaimos at gmail dot com>
 */

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\UserResource as UserResource;
use App\Http\Resources\UserCollection;
use App\Models\User;
use Hash;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Str;
use Illuminate\Validation\Rule;
use Laravel\Fortify\Rules\Password;

class UserController extends Controller
{

    /**
     * Display a listing of the resource.
     *
     * @param  \Illuminate\Http\Request  $request
     *
     * @return \App\Http\Resources\UserCollection
     * @throws \Illuminate\Auth\Access\AuthorizationException
     */
    public function index(Request $request): UserCollection
    {
        $this->authorize('viewAny', User::class);
        abort_unless($request->user()->tokenCan('read'), 403, 'User token is not allowed to read objects');

        return new UserCollection($this->handleBuilderRequest($request, User::query()));
    }

    /**
     * Store a newly created resource in storage.
     *
     * @param  \Illuminate\Http\Request  $request
     *
     * @return \App\Http\Resources\UserResource
     * @throws \Illuminate\Validation\ValidationException
     * @throws \Illuminate\Auth\Access\AuthorizationException
     */
    public function store(Request $request): UserResource
    {
        $this->authorize('create', User::class);
        abort_unless($request->user()->tokenCan('read'), 403, 'User token is not allowed to read objects');
        abort_unless($request->user()->tokenCan('create'), 403, 'User token is not allowed to create objects');
        $values = $this->validate(
            $request,
            [
                'name'     => ['required', 'string', 'max:255'],
                'email'    => ['required', 'string', 'email', 'max:255', Rule::unique('users', 'email')],
                'password' => ['required', 'string', new Password()],
                'admin'    => ['filled', 'boolean'],
                'role'     => ['required', Rule::in(config('constants.roles'))],
            ]
        );
        $model = User::create(
            [
                'name'              => $values['name'],
                'email'             => $values['email'],
                'email_verified_at' => now(),
                'password'          => Hash::make($values['password']),
                'remember_token'    => Str::random(10),
                'admin'             => $values['admin'] ?? false,
                'role'              => $values['role'],
            ]
        )->save();

        return new UserResource($model);
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
        $this->authorize('view', $user);
        abort_unless($request->user()->tokenCan('read'), 403, 'User token is not allowed to read objects');

        return new UserResource($user);
    }

    /**
     * Update the specified resource in storage.
     *
     * @param  \Illuminate\Http\Request  $request
     * @param  \App\Models\User  $user
     *
     * @return \App\Http\Resources\UserResource
     * @throws \Illuminate\Validation\ValidationException
     * @throws \Illuminate\Auth\Access\AuthorizationException
     */
    public function update(Request $request, User $user): UserResource
    {
        $this->authorize('update', $user);
        abort_unless($request->user()->tokenCan('read'), 403, 'User token is not allowed to read objects');
        abort_unless($request->user()->tokenCan('update'), 403, 'User token is not allowed to update objects');
        $rules = [
            'name'         => ['filled', 'string', 'max:255'],
            'email'        => ['filled', 'string', 'email', 'max:255', Rule::unique('users', 'email')],
            'password'     => ['required_with_all:new_password', 'password'],
            'new_password' => ['filled', 'string', new Password()],
            'admin'        => ['filled', 'boolean'],
            'role'         => ['filled', Rule::in(config('constants.roles'))],
        ];
        if ($request->user()->admin) {
            unset($rules['password']);
        }
        $values = $this->validate($request, $rules);
        if (isset($values['name'])) {
            $user->name = $values['name'];
        }
        if (isset($values['email'])) {
            $user->email = $values['email'];
            $user->email_verified_at = now();
        }
        if (isset($values['admin']) && $request->user()->admin && $request->user()->id !== $user->id) {
            $user->admin = (bool)$values['admin'];
        }
        if (isset($values['new_password'])) {
            $user->password = Hash::make($values['new_password']);
        }
        if (isset($values['role'])) {
            $user->role = $values['role'];
        }
        $user->save();

        return new UserResource($user);
    }

    /**
     * Remove the specified resource from storage.
     *
     * @param  \Illuminate\Http\Request  $request
     * @param  \App\Models\User  $user
     *
     * @return \Illuminate\Http\JsonResponse
     * @throws \Exception
     */
    public function destroy(Request $request, User $user): JsonResponse
    {
        $this->authorize('delete', $user);
        abort_unless($request->user()->tokenCan('read'), 403, 'User token is not allowed to read objects');
        abort_unless($request->user()->tokenCan('delete'), 403, 'User token is not allowed to delete objects');
        $user->deleteProfilePhoto();
        /** @noinspection PhpUndefinedMethodInspection */
        $user->tokens->each->delete();
        $user->delete();

        return response()->json(
            [
                'message' => 'User deleted.',
                'errors'  => false,
            ]
        );
    }

    /**
     * Make a new token for the provided user
     *
     * @param  \Illuminate\Http\Request  $request
     * @param  \App\Models\User  $user
     *
     * @return \Illuminate\Http\JsonResponse
     * @throws \Illuminate\Auth\Access\AuthorizationException
     */
    public function token(Request $request, User $user): JsonResponse
    {
        $this->authorize('generateToken', $user);
        abort_unless($request->user()->tokenCan('read'), 403, 'User token is not allowed to read objects');
        abort_unless($request->user()->tokenCan('create'), 403, 'User token is not allowed to create objects');
        $key = Str::random(5);
        $token = $user->createToken(
            'api-call-token-' . $key,
            [
                'create',
                'read',
                'update',
                'delete',
            ]
        );

        return response()->json(
            [
                'data'  => [
                    'id'        => $user->id,
                    'api_token' => $token->plainTextToken,
                ],
                'links' => [
                    'self' => route('users.show', $user),
                ],
            ]
        );
    }
}
