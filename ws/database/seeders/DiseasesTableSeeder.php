<?php

namespace Database\Seeders;

use App\Models\Disease;
use Illuminate\Database\Seeder;

class DiseasesTableSeeder extends Seeder
{
    /**
     * Run the database seeds.
     *
     * @return void
     */
    public function run(): void
    {
        $allDiseases = Disease::select(['id', 'icd_code'])->pluck('id', 'icd_code');
        $toInsert = [];
        $now = now()->toDateTimeString();
        $path = realpath(config('oncoreport.databases_path') . '/Disease.txt');
        if (!empty($path) && file_exists($path) && is_readable($path)) {
            $fp = @fopen($path, 'rb');
            fgetcsv($fp, separator: "\t");
            while (($line = fgetcsv($fp, separator: "\t")) !== false) {
                $icdCodes =
                    collect(explode(',', trim($line[2])))
                        ->flatMap(fn($x) => explode('/', $x))
                        ->map('trim')
                        ->filter()
                        ->unique();
                $name = trim($line[1]);
                $tumor = (int)($line[3]) === 1;
                foreach ($icdCodes as $code) {
                    if (!isset($allDiseases[$code])) {
                        $toInsert[] = [
                            'icd_code'   => $code,
                            'name'       => $name,
                            'tumor'      => $tumor,
                            'created_at' => $now,
                            'updated_at' => $now,
                        ];
                        $allDiseases[$code] = 1;
                    }
                    if (count($toInsert) === 5000) {
                        Disease::insert($toInsert);
                        $toInsert = [];
                    }
                }
            }
            @fclose($fp);
            if (count($toInsert) > 0) {
                Disease::insert($toInsert);
            }
        }
    }
}
