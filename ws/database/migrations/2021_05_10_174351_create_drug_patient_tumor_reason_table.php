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
            $table->unsignedBigInteger('drug_patient_tumor_id');
            $table->unsignedBigInteger('reason_id');
            $table->timestamps();

            $table->foreign('drug_patient_tumor_id')->references('id')->on('drug_patient_tumor')->onDelete('cascade');

            //$table->foreign('drug_patient_tumor_id')->references('id')->on('drug_patient_tumor')->onDelete('cascade');
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
