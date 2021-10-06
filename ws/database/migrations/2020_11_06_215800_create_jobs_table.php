<?php

use App\Constants;
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class CreateJobsTable extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up(): void
    {
        Schema::create(
            'jobs',
            static function (Blueprint $table) {
                $table->id();
                $table->string('sample_code')->nullable()->index();
                $table->string('name')->nullable()->default(null);
                $table->string('job_type');
                $table->enum('status', Constants::JOB_STATES)->default(Constants::READY);
                $table->json('job_parameters');
                $table->json('job_output');
                $table->longText('log');
                $table->foreignId('owner_id')->nullable()->constrained('users')->nullOnDelete();
                $table->foreignId('patient_id')->nullable()->constrained()->nullOnDelete();
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
        Schema::dropIfExists('jobs');
    }
}
