<?php

return [

    'cloud_env'        => env('CLOUD_ENV', false),
    'bash_script_path' => env('BASH_SCRIPT_PATH', '/oncoreport/scripts'),
    'databases_path'   => env('DATABASES_PATH', '/oncoreport/databases'),
    'genomes_path'     => env('GENOMES_PATH', '/oncoreport/ws/storage/app/genomes'),
    'cosmic_path'      => env('COSMIC_PATH', '/oncoreport/ws/storage/app/cosmic'),
    'config_generator' => env('APP_CONFIG_GENERATOR', false),
    'db_versions'      => env('DATABASES_PATH', '/oncoreport/databases').'/versions.txt',
    'cosmic_version'   => env('COSMIC_PATH', '/oncoreport/ws/storage/app/cosmic').'/version.txt',

];
