<?php

namespace Database\Seeders;

use App\Models\Medicine;
use Illuminate\Database\Seeder;

class MedicineSeeder extends Seeder
{
    /**
     * Run the database seeds.
     *
     * @return void
     */
    public function run()
    {
        $path = realpath(env('DATABASES_PATH') . '/drugs.txt');
        $path = '../databases/drugs.txt';
        if (!empty($path) && file_exists($path) && is_readable($path)) {
            $fp = @fopen($path, 'rb');
            while (!feof($fp) && ($line = @fgets($fp)) !== false){
                Medicine::create(['name' => trim($line)])->save();
            }
            @fclose($fp);
        }
    }
}
