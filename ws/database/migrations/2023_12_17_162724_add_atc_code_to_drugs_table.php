<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class AddAtcCodeToDrugsTable extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up(): void
    {
        Schema::table(
            'drugs',
            static function (Blueprint $table) {
                $table->string('atc_code')->nullable();
                $table->index('drugbank_id');
                $table->index('name');
                $table->index('atc_code');
            }
        );
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down(): void
    {
        Schema::table(
            'drugs',
            static function (Blueprint $table) {
                $table->dropColumn('atc_code');
            }
        );
    }
}
