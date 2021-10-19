<?php

namespace App\Http\Services;

use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Collection;
use Illuminate\Http\Request;

class BuilderRequestService
{

    /**
     * Handle a complex request with filtering, ordering, and pagination
     *
     * @param  \Illuminate\Http\Request  $request
     * @param  \Illuminate\Database\Eloquent\Builder  $builder
     * @param  callable|null  $callback
     * @param  string  $defaultOrderField
     * @param  string  $defaultOrdering
     * @param  bool  $paginate
     * @param  int  $defaultPerPage
     *
     * @return \Illuminate\Contracts\Pagination\LengthAwarePaginator|\Illuminate\Database\Eloquent\Builder[]|\Illuminate\Database\Eloquent\Collection
     */
    public function handle(
        Request $request,
        Builder $builder,
        ?callable $callback = null,
        string $defaultOrderField = 'created_at',
        string $defaultOrdering = 'desc',
        bool $paginate = true,
        int $defaultPerPage = 15
    ): Collection|LengthAwarePaginator|array {
        $this->handleFilter($request, $builder);
        $this->handleOrdering($request, $builder, $defaultOrderField, $defaultOrdering);
        if ($callback !== null && is_callable($callback)) {
            $callback($builder, $request);
        }

        return $this->handlePagination($request, $builder, $paginate, $defaultPerPage);
    }

    protected function handleFilter(Request $request, Builder $builder): void
    {
        if ($request->has('filter_by')) {
            $filterBy = $request->input('filter_by');
            $filterValue = $request->input('filter_value');
            if ($filterBy && $filterValue) {
                $filterValue = '%' . $filterValue . '%';
                if (is_array($filterBy)) {
                    $filterBy = array_filter($filterBy);
                    if (count($filterBy) > 0) {
                        $builder->where(function ($q) use ($filterBy, $filterValue) {
                            foreach ($filterBy as $field) {
                                $q->orWhere($field, 'LIKE', $filterValue);
                            }
                        });
                    }
                } else {
                    $builder->where($filterBy, 'LIKE', $filterValue);
                }
            }
        }
    }

    protected function handleOrdering(
        Request $request,
        Builder $builder,
        string $defaultOrderField,
        string $defaultOrdering
    ): void {
        $orderBy = (array)($request->input('order') ?? [$defaultOrderField]);
        $orderDirection = (array)($request->input('order_direction') ?? [$defaultOrdering]);
        if (!empty($orderBy)) {
            for ($i = 0, $count = count($orderBy); $i < $count; $i++) {
                if ($orderBy[$i]) {
                    $builder->orderBy($orderBy[$i], $orderDirection[$i] ?? $defaultOrdering);
                }
            }
        }
    }

    protected function handlePagination(
        Request $request,
        Builder $builder,
        bool $paginate,
        int $defaultPerPage
    ): Collection|LengthAwarePaginator|array {
        $perPage = (int)($request->input('per_page') ?? $defaultPerPage);
        if ($paginate && $perPage > 0) {
            return $builder->paginate($perPage)->appends($request->input());
        }

        return $builder->get();
    }

    public function handleWithGlobalSearch(
        Request $request,
        Builder $builder,
        array $searchableFields = [],
        ?callable $callback = null,
        string $defaultOrderField = 'created_at',
        string $defaultOrdering = 'desc',
        bool $paginate = true,
        int $defaultPerPage = 15
    ): Collection|LengthAwarePaginator|array {
        if ($request->has('search') && count($searchableFields) > 0) {
            $searchValue = $request->input('search');
            if ($searchValue) {
                $filterValue = '%' . $searchValue . '%';
                $builder->where(function ($q) use ($searchableFields, $filterValue) {
                    foreach ($searchableFields as $field) {
                        $q->orWhere($field, 'LIKE', $filterValue);
                    }
                });
                $paginate = false;
            }
        }
        $this->handleOrdering($request, $builder, $defaultOrderField, $defaultOrdering);
        if ($callback !== null && is_callable($callback)) {
            $callback($builder, $request);
        }

        return $this->handlePagination($request, $builder, $paginate, $defaultPerPage);
    }

}