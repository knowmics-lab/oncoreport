<?php

namespace App\Traits;

use Illuminate\Support\Carbon;

trait UseNullableValues
{
    protected function nullableId(mixed $value): ?int
    {
        $value = (int)$value;

        return ($value <= 0) ? null : $value;
    }

    protected function nullableValue(mixed $value): mixed
    {
        return (empty($value)) ? null : $value;
    }

    protected function nullableDate(mixed $value): ?Carbon
    {
        return (empty($value)) ? null : Carbon::make($value);
    }

    protected function dateOrNowIfEmpty(mixed $value): Carbon
    {
        return $this->nullableDate($value) ?? now();
    }

    protected function old(string $field, array $newData, array $oldData, bool $update = true): mixed
    {
        if ($update && !isset($newData[$field])) {
            return $oldData[$field] ?? null;
        }

        return $newData[$field] ?? null;
    }
}