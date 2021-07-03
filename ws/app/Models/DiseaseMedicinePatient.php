<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\Relations\Pivot;

class DiseaseMedicinePatient extends Pivot
{
    /**
     * The reasons that belong to the DiseaseMedicinePatient
     *
     * @return \Illuminate\Database\Eloquent\Relations\BelongsToMany
     */
    public function reasons(): BelongsToMany
    {
        return $this->belongsToMany(Reason::class);
    }
}
