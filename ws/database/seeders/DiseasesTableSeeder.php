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
        $path = realpath(env('DATABASES_PATH') . '/disease_list.txt');
        if (!empty($path) && file_exists($path) && is_readable($path)) {
            $fp = @fopen($path, 'rb');
            fgets($fp);
            while (!feof($fp) && ($line = @fgets($fp)) !== false) {
                Disease::create(
                    [
                        'name' => trim($line),
                    ]
                )->save();
            }
            @fclose($fp);
        }
    }
}
