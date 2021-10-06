<?php

namespace App;

class Constants
{

    public const ADMIN     = 'admin';
    public const DOCTOR    = 'doctor';
    public const TECHNICAL = 'technical';
    public const PATIENT   = 'patient';
    public const ROLES     = [
        self::ADMIN,
        self::DOCTOR,
        self::TECHNICAL,
        self::PATIENT,
    ];


}