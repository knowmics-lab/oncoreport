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
        $path = realpath(env('DATABASES_PATH') . '/cancer_drugs.txt');
        if (!empty($path) && file_exists($path) && is_readable($path)) {
            $fp = @fopen($path, 'rb');
            while (!feof($fp) && ($line = @fgets($fp)) !== false) {
                Drug::firstOrCreate(
                    [
                        'name' => trim($line),
                    ]
                );
            }
            @fclose($fp);
        }
    }
}
