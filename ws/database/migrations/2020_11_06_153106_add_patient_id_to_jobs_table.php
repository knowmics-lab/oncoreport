<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class AddPatientIdToJobsTable extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up(): void
    {
        Schema::table(
            'jobs',
            static function (Blueprint $table) {
                $table->unsignedBigInteger('patient_id')->after('log')->nullable()->index();
                $table->foreign('patient_id', 'patient_id_to_patient_foreign_key')->references('id')->on('patients')
                      ->onDelete('set null')->onUpdate('set null');
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
            'jobs',
            static function (Blueprint $table) {
                $table->dropForeign('patient_id_to_patient_foreign_key');
                $table->dropColumn('patient_id');
            }
        );
    }
}
