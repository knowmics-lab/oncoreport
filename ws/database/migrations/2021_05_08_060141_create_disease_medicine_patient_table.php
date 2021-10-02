<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class CreateDiseaseMedicinePatientTable extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up(): void
    {
        Schema::create('disease_medicine_patient', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('disease_patient_id');
            $table->unsignedBigInteger('medicine_id');
            $table->timestamps();

            $table->foreign('disease_patient_id')->references('id')->on('disease_patient')->onDelete('cascade');
        });
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down(): void
    {
        Schema::dropIfExists('disease_medicine_patient');
    }
}
