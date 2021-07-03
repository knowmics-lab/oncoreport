<?php

namespace Database\Seeders;

use App\Models\Drug;
use Illuminate\Database\Seeder;

class DrugSeeder extends Seeder
{
    /**
     * Run the database seeds.
     *
     * @return void
     */
    public function run()
    {
        $path = realpath(env('RELATIVE_PATH_PREFIX') . env('DATABASES_PATH') . '/cancer_drugs.txt');
        //$path = '../databases/cancer_drugs.txt';
        if (!empty($path) && file_exists($path) && is_readable($path)) {
            $fp = @fopen($path, 'rb');
            while (!feof($fp) && ($line = @fgets($fp)) !== false){
                Drug::create(['name' => trim($line)])->save();
            }
            @fclose($fp);
        }
    }
}
