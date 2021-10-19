<?php
/**
 * Oncoreport Web Service
 *
 * @author S. Alaimo, Ph.D. <alaimos at gmail dot com>
 */

namespace App\Models;

class Disease extends Resource
{

    /**
     * The attributes that are mass assignable.
     *
     * @var array
     */
    protected $fillable = [
        'icd_code',
        'name',
        'tumor',
    ];

    protected $casts = [
        'tumor' => 'bool',
    ];

}
