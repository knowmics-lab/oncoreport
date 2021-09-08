<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class CreatePatientsTable extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up(): void
    {
        Schema::create(
            'patients',
            static function (Blueprint $table) {
                $table->id();
                $table->string('code');
                $table->string('first_name');
                $table->string('last_name');
                $table->enum('gender', ['m', 'f']);
                $table->tinyInteger('age');
                $table->string('email');
                $table->string('fiscal_number')->unique();
                $table->unsignedBigInteger('user_id')->nullable()->index();
                $table->foreign('user_id', 'user_id_to_patient_foreign_key')
                      ->references('id')->on('users')
                      ->onDelete('set null')->onUpdate('set null');
                $table->timestamps();

                $table->string('password');
                $table->rememberToken();
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
        Schema::dropIfExists('patients');
    }
}
