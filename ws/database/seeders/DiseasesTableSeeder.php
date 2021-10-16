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
                foreach ($icdCodes as $code) {
                    Disease::firstOrCreate(
                        [
                            'icd10_code' => $code,
                        ],
                        [
                            'name' => trim($line[1]),
                            'tumor' => (int)($line[3]) === 1,
                        ]
                    );
                }
            }
            @fclose($fp);
        }
    }
}
