<?php

namespace Database\Seeders;

use App\Models\Reason;
use Illuminate\Database\Seeder;

class ReasonSeeder extends Seeder
{
    /**
     * Run the database seeds.
     *
     * @return void
     */
    public function run()
    {


        $path = realpath(env('DATABASES_PATH') . '/reasons.txt');
        $path = '../databases/reasons.txt';
        if (!empty($path) && file_exists($path) && is_readable($path)) {
            $fp = @fopen($path, 'rb');
            while (!feof($fp) && ($line = @fgets($fp)) !== false){
                Reason::create(['name' => trim($line)])->save();
            }
            @fclose($fp);
        }

        #Reason::create(['name' => 'rigetto'])->save();
        #Reason::create(['name' => 'reazione allergica'])->save();
        Reason::create(['name' => 'other'])->save();
    }
}
