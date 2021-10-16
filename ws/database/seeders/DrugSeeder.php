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
        $allDrugs = Drug::select(['id', 'drugbank_id'])->pluck('id', 'drugbank_id');
        $toInsert = [];
        $now = now()->toDateTimeString();
        $path = realpath(config('oncoreport.databases_path') . '/drug_info.csv');
        if (!empty($path) && file_exists($path) && is_readable($path)) {
            $fp = @fopen($path, 'rb');
            fgetcsv($fp);
            while (($line = fgetcsv($fp)) !== false) {
                $id = trim($line[0]);
                if (!isset($allDrugs[$id])) {
                    $toInsert[] = [
                        'drugbank_id' => $id,
                        'name'        => trim($line[1]),
                        'created_at'  => $now,
                        'updated_at'  => $now,
                    ];
                    $allDrugs[$id] = 1;
                }
                if (count($toInsert) === 5000) {
                    Drug::insert($toInsert);
                    $toInsert = [];
                }
            }
            @fclose($fp);
        }
        if (count($toInsert) > 0) {
            Drug::insert($toInsert);
        }
    }
}
