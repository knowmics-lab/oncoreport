<?php
/**
 * Oncoreport Web Service
 *
 * @author S. Alaimo, Ph.D. <alaimos at gmail dot com>
 */

namespace App\Console\Commands;

use App\Exceptions\ProcessingJobException;
use App\Jobs\Types\AbstractJob;
use App\Utils;
use Exception;
use Illuminate\Console\Command;
use Symfony\Component\Process\Process;

class UpdateRun extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'update:run';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Runs the update script';

    /**
     * Execute the console command.
     *
     * @return mixed
     */
    public function handle(): int
    {
        try {
            $retCode = $this->runScript('pre_update.bash');
            if ($retCode !== 0) {
                return $retCode;
            }
            $retCode = $this->call(
                'migrate',
                [
                    '--force'          => true,
                    '--no-interaction' => true,
                ]
            );
            if ($retCode !== 0) {
                return $retCode;
            }
            $retCode = $this->call(
                'db:seed',
                [
                    '--force'          => true,
                    '--no-interaction' => true,
                ]
            );
            if ($retCode !== 0) {
                return $retCode;
            }
            $retCode = $this->runScript('post_update.bash', true);
            if ($retCode !== 0) {
                return $retCode;
            }
            $versionNumberFile = Utils::currentVersionFilePath();
            @unlink($versionNumberFile);
            copy(Utils::containerVersionFilePath(), $versionNumberFile);
            @chmod($versionNumberFile, 0644);
        } catch (Exception $e) {
            $this->error($e->getMessage());

            return 1;
        }

        return 0;
    }

    /**
     * Execute an update script
     *
     * @param  string  $script
     * @param  bool  $warn
     *
     * @return int
     * @throws \Exception
     */
    protected function runScript(string $script, bool $warn = false): int
    {
        $updateScript = AbstractJob::scriptPath($script);
        if (file_exists($updateScript)) {
            try {
                AbstractJob::runCommand(
                    command: [
                                 'bash',
                                 $updateScript,
                             ],
                    callback: function ($type, $buffer) {
                        if ($type === Process::ERR) {
                            $this->output->write('<error>'.$buffer.'</error>');
                        } else {
                            $this->output->write($buffer);
                        }
                    },
                    env:     true
                );
            } catch (ProcessingJobException $e) {
                $this->error($e->getMessage());

                return 100;
            }
        } elseif ($warn) {
            $this->warn('No update script to run');
        }
        $this->output->newLine();

        return 0;
    }
}
