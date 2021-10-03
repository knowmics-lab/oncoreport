<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class AddFieldsToPatientsTable extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up(): void
    {
        Schema::table('patients', static function (Blueprint $table) {
            $table->string('email');
            $table->string('fiscal_number')->unique();
            $table->integer('T')->nullable();
            $table->integer('N')->nullable();
            $table->integer('M')->nullable();
            $table->unsignedBigInteger('location_id')->nullable();
            $table->string('telephone')->nullable();
            $table->string('city')->nullable();
            $table->string('password');
            $table->rememberToken();
        });
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down(): void
    {
    }
}
