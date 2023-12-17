<?php
/**
 * Oncoreport Web Service
 *
 * @author S. Alaimo, Ph.D. <alaimos at gmail dot com>
 */

namespace App\Console\Commands;

use App\Utils;
use Illuminate\Console\Command;

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
        $versionNumberFile = Utils::currentVersionFilePath();
        if (!file_exists($versionNumberFile)) {
            copy(Utils::containerVersionFilePath(), $versionNumberFile);
            @chmod($versionNumberFile, 0644);
        }

        return 0;
    }
}
