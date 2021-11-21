<?php
/**
 * Oncoreport Web Service
 *
 * @author S. Alaimo, Ph.D. <alaimos at gmail dot com>
 */

namespace App\Console\Commands;

use App\Utils;
use Illuminate\Console\Command;
use JsonException;

class FirstBoot extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'first:boot';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Runs some commands that are required on first boot';

    /**
     * Execute the console command.
     *
     * @return mixed
     */
    public function handle(): int
    {
        $versionNumberFile = storage_path('app/version_number');
        if (!file_exists($versionNumberFile)) {
            try {
                @file_put_contents(
                    $versionNumberFile,
                    json_encode(
                        [
                            'version' => Utils::VERSION_NUMBER,
                        ],
                        JSON_THROW_ON_ERROR
                    )
                );
            } catch (JsonException $e) {
                $this->error($e->getMessage());

                return 1;
            }
            @chmod($versionNumberFile, 0644);
        }

        return 0;
    }
}
