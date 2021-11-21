<?php

return [

    'cloud_env'        => env('CLOUD_ENV', true), // @todo: change from true to false
    'bash_script_path' => env('BASH_SCRIPT_PATH', '/oncoreport/scripts'),
    'databases_path'   => env('DATABASES_PATH', '/oncoreport/databases'),
    'genomes_path'     => env('GENOMES_PATH', '/oncoreport/ws/storage/app/genomes'),
    'cosmic_path'      => env('COSMIC_PATH', '/oncoreport/ws/storage/app/cosmic'),

];
