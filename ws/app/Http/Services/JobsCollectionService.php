<?php

namespace App\Http\Services;

use App\Constants;
use App\Http\Resources\JobResource;
use App\Models\Job;
use App\Models\Patient;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;

class JobsCollectionService
{

    public function __construct(private BuilderRequestService $requestService) { }

    public function build(Request $request, Builder $builder): AnonymousResourceCollection
    {
        return JobResource::collection(
            $this->requestService->handle(
                $request,
                $builder,
                static function (Builder $builder, Request $request) {
                    if ($request->boolean('completed')) {
                        $builder->where('status', Constants::COMPLETED);
                    }
                    if ($request->has('type') && ($type = $request->input('type'))) {
                        $builder->where('job_type', $type);
                    }
                    if ($request->has('patient') && ($id = (int)$request->input('patient'))) {
                        $builder->where('patient', $id);
                    }
                }
            )
        );
    }

}