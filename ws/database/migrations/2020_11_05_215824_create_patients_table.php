<?php

use App\Constants;
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
                $table->enum('gender', Constants::GENDERS);
                $table->tinyInteger('age');
                $table->string('email')->nullable();
                $table->string('fiscal_number')->nullable();
                $table->string('telephone')->nullable();
                $table->string('city')->nullable();
                $table->foreignId('user_id')->nullable()->constrained('users')->nullOnDelete();
                $table->foreignId('owner_id')->nullable()->constrained('users')->nullOnDelete();
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
        Schema::dropIfExists('patients');
    }
}
