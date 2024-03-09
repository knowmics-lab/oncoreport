<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\Schema;

class UpgradeTablesV2 extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up(): void
    {
        if (Schema::hasColumn('patients', 'email')) {
            Schema::dropColumns('patients', 'email');
        }
        if (Schema::hasColumn('patients', 'fiscal_number')) {
            Schema::dropColumns('patients', 'fiscal_number');
        }
        if (Schema::hasColumn('patients', 'telephone')) {
            Schema::dropColumns('patients', 'telephone');
        }
        if (Schema::hasColumn('patients', 'city')) {
            Schema::dropColumns('patients', 'city');
        }
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down(): void
    {
        //
    }
}
