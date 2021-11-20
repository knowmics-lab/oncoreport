<?php

use App\Constants;
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class CreatePatientDiseasesTable extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up(): void
    {
        Schema::create(
            'patient_diseases',
            static function (Blueprint $table) {
                $table->id();
                $table->foreignId('patient_id')->constrained()->cascadeOnDelete();
                $table->foreignId('disease_id')->constrained()->cascadeOnDelete();
                $table->enum('type', Constants::TUMOR_TYPES)->nullable();
                $table->integer('T')->nullable();
                $table->integer('N')->nullable();
                $table->integer('M')->nullable();
                $table->date('start_date')->nullable();
                $table->date('end_date')->nullable();
                $table->timestamps();
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
        Schema::dropIfExists('patient_diseases');
    }
}
