<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class CreateDrugPatientTumorTable extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        Schema::create('drug_patient_tumor', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('patient_tumor_id');
            $table->unsignedBigInteger('drug_id');
            $table->date('start_date')->nullable();
            $table->date('end_date')->nullable();
            //$table->unsignedBigInteger('reason_id')->nullable();
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
        Schema::dropIfExists('drug_patient_tumor');
    }
}
