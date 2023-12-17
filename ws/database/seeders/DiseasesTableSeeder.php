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
        $allDiseases = Disease::select(['id', 'doid'])->pluck('id', 'doid');
        $toInsert = [];
        $now = now()->toDateTimeString();
        $path = realpath(config('oncoreport.databases_path').'/diseases.tsv');
        if (!empty($path) && file_exists($path) && is_readable($path)) {
            $fp = @fopen($path, 'rb');
            fgetcsv($fp, separator: "\t");
            while (($line = fgetcsv($fp, separator: "\t")) !== false) {
                if ((int)($line[4]) === 1) {
                    continue;
                }
                $doids =
                    collect(explode(',', trim($line[2])))
                        ->flatMap(fn($x) => explode('/', $x))
                        ->map(fn($x) => trim($x))
                        ->filter()
                        ->unique();
                $name = trim($line[1]);
                $tumor = (int)($line[3]) === 1;
                foreach ($doids as $doid) {
                    if (!isset($allDiseases[$doid])) {
                        $toInsert[] = [
                            'doid'       => $doid,
                            'name'       => $name,
                            'tumor'      => $tumor,
                            'created_at' => $now,
                            'updated_at' => $now,
                        ];
                        $allDiseases[$doid] = 1;
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
