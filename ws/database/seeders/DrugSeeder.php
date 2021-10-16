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
    public function run(): void
    {
        $path = realpath(config('oncoreport.databases_path') . '/drug_info.csv');
        if (!empty($path) && file_exists($path) && is_readable($path)) {
            $fp = @fopen($path, 'rb');
            fgetcsv($fp);
            while (($line = fgetcsv($fp)) !== false) {
                Drug::firstOrCreate(
                    [
                        'drugbank_id' => trim($line[0]),
                    ],
                    [
                        'name' => trim($line[1]),
                    ]
                );
            }
            @fclose($fp);
        }
    }
}
