<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class CreatePatientDrugSuspensionReasonTable extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up(): void
    {
        Schema::create('patient_drug_suspension_reason', static function (Blueprint $table) {
            $table->foreignId('patient_drug_id')->constrained()->cascadeOnDelete();
            $table->foreignId('suspension_reason_id')->constrained()->cascadeOnDelete();
        });
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down(): void
    {
        Schema::dropIfExists('patient_drug_suspension_reason');
    }
}
