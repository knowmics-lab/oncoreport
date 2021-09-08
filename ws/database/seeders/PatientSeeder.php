<?php

namespace Database\Seeders;

use App\Models\Patient;
use Illuminate\Database\Seeder;

class PatientSeeder extends Seeder
{
    /**
     * Run the database seeds.
     *
     * @return void
     */
    public function run()
    {
        $patient = Patient::create(
            [
                'code'          => 000,
                'first_name'    => 'test',
                'last_name'     => 'test',
                'gender'        => 'm',
                'age'           => 90,
                'disease_id'    => 1,
                'user_id'       => 1,
                "fiscal_number" => '000000',
                "email"         => 'email@email.com',
                'password'      => '$2y$10$TKh8H1.PfQx37YgCzwiKb.KjNyWgaHb9cbcoQgdIVFlYg7B77UdFm', // secret
            ]
        );
        $patient->save();
    }
}
