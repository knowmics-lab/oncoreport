<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class CreateDiseaseMedicinePatientReasonTable extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up(): void
    {
        Schema::create('disease_medicine_patient_reason', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('disease_medicine_patient_id');
            $table->unsignedBigInteger('reason_id');
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down(): void
    {
        Schema::dropIfExists('disease_medicine_patient_reason');
    }
}
