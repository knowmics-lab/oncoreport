<?php
/**
 * Oncoreport Web Service
 *
 * @author S. Alaimo, Ph.D. <alaimos at gmail dot com>
 */

namespace App\Console\Commands;

use App\Http\Services\SystemInfoService;
use Illuminate\Console\Command;
use Throwable;

class CheckForUpdate extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'update:check';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Checks if the update script should be started';


    /**
     * Execute the console command.
     *
     * @return mixed
     */
    public function handle(): int
    {
        try {
            $this->line(
                json_encode(
                    [
                        'updateNeeded' => (new SystemInfoService())->isUpdateNeeded(),
                    ],
                    JSON_THROW_ON_ERROR
                )
            );
        } catch (Throwable $e) {
            $this->error($e->getMessage());

            return 100;
        }

        return 0;
    }
}
