<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class AddDiseaseIdToPatientsTable extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up(): void
    {
        Schema::table(
            'patients',
            static function (Blueprint $table) {
                $table->unsignedBigInteger('disease_id')->after('age')->index();
                $table->foreign('disease_id', 'disease_id_to_diseases_foreign_key')
                      ->references('id')->on('diseases')->restrictOnDelete();
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
            'patients',
            static function (Blueprint $table) {
                $table->dropForeign('disease_id_to_diseases_foreign_key');
                $table->dropColumn('disease_id');
            }
        );
    }
}
