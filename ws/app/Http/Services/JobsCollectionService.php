<?php

namespace App\Http\Services;

use App\Constants;
use App\Models\Job;
use App\Models\Patient;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Http\Request;

class JobsCollectionService
{

    public function __construct(private BuilderRequestService $requestService) { }

    public function build(Request $request, Builder $builder)
    {
        $this->requestService->handle(
            $request,
            $builder,
            static function (Builder $builder, Request $request) {
                if ($request->has('completed')) {
                    $builder->where('status', Constants::COMPLETED);
                }
                $user = optional($request->user());
                if ($user->role === Constants::PATIENT) {
                    $patientId = Patient::where('user_id', $user->id)->firstOrFail(['id'])->id;
                    $builder->whereNotNull('patient_id')->where('patient_id', $patientId);
                } elseif ($user->role === Constants::DOCTOR) {
                    $builder->where(function (Builder $b) use ($user) {
                        $b->whereNull('owner_id')->orWhere('owner_id', $user->id);
                    });
                }
            }
        );
        $this->handleBuilderRequest(
            $request,
            $query,
            static function (Builder $builder) use ($request) {
                if ($request->has('completed')) {
                    $builder->where('status', '=', Job::COMPLETED);
                }
                /** @var \App\Models\User $user */
                $user = optional($request->user());
                if (!$user->admin) {
                    $builder->where('user_id', $user->id);
                }

                return $builder;
            }
        )
    }

}