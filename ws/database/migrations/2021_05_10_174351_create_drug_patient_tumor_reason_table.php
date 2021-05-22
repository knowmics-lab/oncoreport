<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class CreateDrugPatientTumorReasonTable extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        Schema::create('drug_patient_tumor_reason', function (Blueprint $table) {
            $table->id();
            $table->unsignedInteger('drug_patient_tumor_id');
            $table->unsignedBigInteger('reason_id');
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::dropIfExists('drug_patient_tumor_reason');
    }
}
