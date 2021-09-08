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
        // for ($i = 1; $i < 10; $i++){
        //     Location::create(['name' => "sede $i"])->save();
        // }

        $path = realpath(env('DATABASES_PATH') . '/cancer_locations.txt');

        $path = '../databases/cancer_locations.txt';
        if (!empty($path) && file_exists($path) && is_readable($path)) {
            $fp = @fopen($path, 'rb');
            while (!feof($fp) && ($line = @fgets($fp)) !== false){
                Location::create(['name' => trim($line)])->save();
            }
            @fclose($fp);
        }

    }
}
