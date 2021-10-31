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

    protected function nullableInteger(mixed $value): ?int
    {
        return is_numeric($value) ? (int)$value : null;
    }

    protected function nullableValue(mixed $value): mixed
    {
        return (empty($value)) ? null : $value;
    }

    protected function dateOrNowIfEmpty(mixed $value): Carbon
    {
        return $this->nullableDate($value) ?? now();
    }

    protected function nullableDate(mixed $value): ?Carbon
    {
        return (empty($value)) ? null : Carbon::make($value);
    }

    protected function old(
        string $field,
        array $newData,
        array $oldData,
        bool $update = true,
        ?string $oldDataField = null,
        bool $mayHaveId = false
    ): mixed {
        if ($oldDataField === null) {
            $oldDataField = $field;
        }
        $fieldWithId = $field . '_id';
        if ($update && !array_key_exists($field, $newData) && (
                !$mayHaveId || !array_key_exists($fieldWithId, $newData)
            )) {
            return $oldData[$oldDataField] ?? null;
        }
        if ($mayHaveId && !array_key_exists($field, $newData) && array_key_exists($fieldWithId, $newData)) {
            return $newData[$fieldWithId] ?? null;
        }

        return $newData[$field] ?? null;
    }
}