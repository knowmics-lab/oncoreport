<?php

namespace Database\Seeders;

use App\Models\SuspensionReason;
use Illuminate\Database\Seeder;

class ReasonSeeder extends Seeder
{
    /**
     * Run the database seeds.
     *
     * @return void
     */
    public function run(): void
    {
        $path = realpath(config('oncoreport.databases_path') . '/reasons.txt');
        if (!empty($path) && file_exists($path) && is_readable($path)) {
            $fp = @fopen($path, 'rb');
            while (!feof($fp) && ($line = @fgets($fp)) !== false) {
                SuspensionReason::firstOrCreate(
                    [
                        'name' => trim($line),
                    ]
                );
            }
            @fclose($fp);
        }
        SuspensionReason::firstOrCreate(
            [
                'name' => 'other',
            ]
        );
    }
}
