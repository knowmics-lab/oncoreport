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
        $atcCodes = Drug::select(['id', 'atc_code'])->pluck('atc_code');
        $toInsert = [];
        $toUpsert = [];
        $now = now()->toDateTimeString();
        $path = realpath(config('oncoreport.databases_path').'/drug_info.csv');
        if (!empty($path) && file_exists($path) && is_readable($path)) {
            $fp = @fopen($path, 'rb');
            fgetcsv($fp);
            while (($line = fgetcsv($fp)) !== false) {
                $id = trim($line[0]);
                $atcCode = trim($line[2]);
                $hasAtcCode = !empty($atcCode) && strtolower($atcCode) !== 'na';
                if (!isset($allDrugs[$id])) {
                    $toInsert[] = [
                        'drugbank_id' => $id,
                        'name'        => trim($line[1]),
                        'atc_code'    => $hasAtcCode ? $atcCode : null,
                        'created_at'  => $now,
                        'updated_at'  => $now,
                    ];
                    $allDrugs[$id] = 1;
                } elseif ($hasAtcCode) {
                    $internalId = $allDrugs[$id];
                    $internalAtcCode = $atcCodes[$internalId];
                    if (empty($internalAtcCode)) {
                        $toUpsert[] = [
                            'drugbank_id' => $id,
                            'name'        => trim($line[1]),
                            'atc_code'    => $atcCode,
                            'created_at'  => $now,
                            'updated_at'  => $now,
                        ];
                    }
                }
                if (count($toInsert) === 5000) {
                    Drug::insert($toInsert);

                    $toInsert = [];
                }
                if (count($toUpsert) === 5000) {
                    Drug::upsert($toUpsert, 'drugbank_id', ['name', 'atc_code', 'updated_at']);

                    $toUpsert = [];
                }
            }
            @fclose($fp);
        }
        if (count($toInsert) > 0) {
            Drug::insert($toInsert);
        }
        if (count($toUpsert) > 0) {
            Drug::upsert($toUpsert, 'drugbank_id', ['name', 'atc_code', 'updated_at']);
        }
    }
}
