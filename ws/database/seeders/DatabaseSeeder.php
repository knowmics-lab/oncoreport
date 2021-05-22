<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    /**
     * Seed the application's database.
     *
     * @return void
     */
    public function run(): void
    {
        $this->call(DiseasesTableSeeder::class);
        $this->call(UsersTableSeeder::class);
        $this->call(TumorSeeder::class);
        $this->call(DrugSeeder::class);
        $this->call(MedicineSeeder::class);
        $this->call(ReasonSeeder::class);
    }
}
