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

    public const GENDERS     = ['m', 'f'];
    public const TUMOR_TYPES = ['primary', 'secondary'];

    public const READY      = 'ready';
    public const QUEUED     = 'queued';
    public const PROCESSING = 'processing';
    public const COMPLETED  = 'completed';
    public const FAILED     = 'failed';
    public const JOB_STATES = [
        self::READY,
        self::QUEUED,
        self::PROCESSING,
        self::COMPLETED,
        self::FAILED,
    ];

}