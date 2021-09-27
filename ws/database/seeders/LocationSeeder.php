<?php

namespace Database\Seeders;

use App\Models\Location;
use Illuminate\Database\Seeder;

class LocationSeeder extends Seeder
{
    /**
     * Run the database seeds.
     *
     * @return void
     */
    public function run()
    {
        $path = realpath(env('DATABASES_PATH') . '/cancer_locations.txt');
        if (!empty($path) && file_exists($path) && is_readable($path)) {
            $fp = @fopen($path, 'rb');
            while (!feof($fp) && ($line = @fgets($fp)) !== false) {
                Location::firstOrCreate(
                    [
                        'name' => trim($line),
                    ]
                );
            }
            @fclose($fp);
        }
    }
}
