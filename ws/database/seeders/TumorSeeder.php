<?php

namespace Database\Seeders;

use App\Models\Tumor;
use Illuminate\Database\Seeder;

class TumorSeeder extends Seeder
{
    /**
     * Run the database seeds.
     *
     * @return void
     */
    public function run()
    {
        $path = realpath(env('DATABASES_PATH') . '/cancer_types.txt');
        $path = '../databases/cancer_types.txt';
        if (!empty($path) && file_exists($path) && is_readable($path)) {
            $fp = @fopen($path, 'rb');
            while (!feof($fp) && ($line = @fgets($fp)) !== false){
                Tumor::create(['name' => trim($line)])->save();
            }
            @fclose($fp);
        }

    }
}
