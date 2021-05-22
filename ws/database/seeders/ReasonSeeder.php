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
        Reason::create(['name' => 'rigetto'])->save();
        Reason::create(['name' => 'reazione allergica'])->save();
        Reason::create(['name' => 'altro'])->save();
    }
}
