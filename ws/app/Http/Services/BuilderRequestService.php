<?php

namespace App\Http\Services;

use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Collection;
use Illuminate\Http\Request;

class BuilderRequestService
{

    private const VALID_OPERANDS = ['<', '<=', '>', '>=', '<>', 'like'];

    /**
     * Handle a complex request with filtering, ordering, and pagination
     *
     * @param  \Illuminate\Http\Request  $request
     * @param  \Illuminate\Database\Eloquent\Builder  $builder
     * @param  callable|null  $callback
     * @param  string  $defaultOrderField
     * @param  string  $defaultOrdering
     * @param  array  $searchableFields
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
        array $searchableFields = [],
        bool $paginate = true,
        int $defaultPerPage = 15
    ): Collection|LengthAwarePaginator|array {
        if (
            $this->handleGlobalSearch($request, $builder, $searchableFields) &&
            $this->handleSimpleFilter($request, $builder)
        ) {
            $this->handleAdvancedFilter($request, $builder);
        }
        $this->handleOrdering($request, $builder, $defaultOrderField, $defaultOrdering);
        if ($callback !== null && is_callable($callback)) {
            $callback($builder, $request);
        }

        return $this->handlePagination($request, $builder, $paginate, $defaultPerPage);
    }

    protected function isInRelationship(string $field): bool
    {
        return str_contains($field, '.');
    }

    protected function extractRelationship(string $field): array
    {
        $relationships = explode('.', $field);
        $realField = array_pop($relationships);

        return [implode('.', $relationships), $realField];
    }

    protected function handleRelationshipField(
        string $field,
        string $operator,
        mixed $value,
        mixed $q,
        $or = false
    ): void {
        [$relationship, $realField] = $this->extractRelationship($field);
        $q->has(
            $relationship,
            boolean: $or ? 'or' : 'and',
            callback: fn($q1) => $q1->where($realField, $operator, $value)
        );
    }

    protected function handleGlobalSearch(
        Request $request,
        Builder $builder,
        array $searchableFields,
    ): bool {
        if ($request->has('search') && count($searchableFields) > 0) {
            $searchValue = $request->input('search');
            if ($searchValue) {
                $filterValue = '%' . $searchValue . '%';
                $builder->where(function ($q) use ($searchableFields, $filterValue) {
                    foreach ($searchableFields as $field) {
                        if ($this->isInRelationship($field)) {
                            $this->handleRelationshipField($field, 'LIKE', $filterValue, $q, true);
                        } else {
                            $q->orWhere($field, 'LIKE', $filterValue);
                        }
                    }
                });

                return false;
            }
        }

        return true;
    }

    protected function handleSimpleFilter(Request $request, Builder $builder): bool
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
                                if ($this->isInRelationship($field)) {
                                    $this->handleRelationshipField($field, 'LIKE', $filterValue, $q, true);
                                } else {
                                    $q->orWhere($field, 'LIKE', $filterValue);
                                }
                            }
                        });

                        return false;
                    }
                } else {
                    $builder->where($filterBy, 'LIKE', $filterValue);

                    return false;
                }
            }
        }

        return true;
    }

    protected function handleAdvancedFilter(Request $request, Builder $builder): void
    {
        if ($request->has('filter')) {
            $filter = (array)$request->input('filter', []);
            foreach ($filter as $specs) {
                $field = $specs['by'] ?? null;
                $operator = strtolower($specs['op'] ?? '=');
                $value = $specs['value'] ?? null;
                if ($field && in_array($operator, self::VALID_OPERANDS, true)) {
                    if ($this->isInRelationship($field)) {
                        $this->handleRelationshipField($field, $operator, $value, $builder);
                    } else {
                        $builder->where($field, $operator, $value);
                    }
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
                if ($field = $orderBy[$i]) {
                    $builder->orderBy($field, $orderDirection[$i] ?? $defaultOrdering);
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
        return $this->handle(
            $request,
            $builder,
            $callback,
            $defaultOrderField,
            $defaultOrdering,
            $searchableFields,
            $paginate,
            $defaultPerPage
        );
    }

}