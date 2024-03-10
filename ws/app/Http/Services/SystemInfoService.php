<?php

namespace App\Http\Services;

use App\Constants;
use App\Jobs\Types\Factory;
use App\Models\Job;
use App\Utils;
use Illuminate\Support\Facades\Cache;
use Symfony\Component\Process\Exception\ProcessFailedException;
use Throwable;

class SystemInfoService
{

    /**
     * Checks if the update script should be executed
     *
     * @return bool
     */
    public function isUpdateNeeded(): bool
    {
        return Utils::containerVersion() > Utils::currentVersion();
    }

    /**
     * Checks if the oncokb token is valid
     *
     * @return array
     */
    public function oncokbTokenStatus(): array
    {
        if (Cache::has('oncokbTokenStatus')) {
            return Cache::get('oncokbTokenStatus');
        }
        $status = 'ok';
        try {
            $statusMessage = Utils::runCommand(
                [
                    'bash',
                    realpath(config('oncoreport.bash_script_path').'/verify_oncokb_key.bash'),
                ]
            );
        } catch (ProcessFailedException $e) {
            $process = $e->getProcess();
            $exitCode = $process->getExitCode();
            if ($exitCode > 0 && $exitCode <= 4) {
                $statusMessage = $process->getOutput();
                $status = ($exitCode === 4) ? 'warning' : 'error';
            } else {
                $status = 'error';
                $statusMessage = $e->getMessage();
            }
        }
        $statusMessage = trim($statusMessage);
        $tokenStatus = ['status' => $status, 'message' => $statusMessage];
        Cache::put('oncokbTokenStatus', $tokenStatus, now()->addDay());

        return $tokenStatus;
    }

    /**
     * Find how much memory this machine has
     *
     * @return int
     */
    public function maxMemory(): int
    {
        if (Cache::has('availableMemory')) {
            return Cache::get('availableMemory');
        }
        $fh = @fopen('/proc/meminfo', 'rb');
        if (!$fh) {
            return -1;
        }
        $mem = -1;
        while ($line = fgets($fh)) {
            $pieces = [];
            if (preg_match('/^MemTotal:\s+(\d+)\skB$/', $line, $pieces)) {
                $mem = (int)$pieces[1];
                break;
            }
        }
        @fclose($fh);
        Cache::put('availableMemory', $mem, now()->addDay());

        return $mem;
    }

    /**
     * Find how much memory is still available on the machine
     *
     * @return int
     */
    public function availableMemory(): int
    {
        if (Cache::has('availableMemory')) {
            return Cache::get('availableMemory');
        }
        $fh = @fopen('/proc/meminfo', 'rb');
        if (!$fh) {
            return -1;
        }
        $mem = -1;
        while ($line = fgets($fh)) {
            $pieces = [];
            if (preg_match('/^MemAvailable:\s+(\d+)\skB$/', $line, $pieces)) {
                $mem = (int)$pieces[1];
                break;
            }
        }
        @fclose($fh);
        Cache::put('availableMemory', $mem, now()->addMinute());

        return $mem;
    }

    /**
     * Count the number of cores available for this machine
     *
     * @return int
     */
    public function numCores(): int
    {
        if (Cache::has('numCores')) {
            return Cache::get('numCores');
        }
        $cpuInfo = file_get_contents('/proc/cpuinfo');
        preg_match_all('/^processor/m', $cpuInfo, $matches);
        $count = count($matches[0]);
        Cache::put('numCores', $count, now()->addDay());

        return $count;
    }

    /**
     * Detect how much cpu cores will be used by the last two analysis.
     * For the detection we take the last 10 jobs to find the maximum number of user threads.
     * Then it multiplies this values by 2 to get a rough estimate.
     * If all jobs are within boundaries (< 1/3 * CPU cores) the number is a correct estimation.
     *
     * @return int
     */
    public function usedCores(): int
    {
        try {
            $jobs = Job::whereIn('status', [Constants::QUEUED, Constants::PROCESSING])
                       ->latest()
                       ->take(10)
                       ->get();
            if ($jobs->count() === 1) {
                return Factory::get($jobs->first())->threads();
            }

            return (2 * $jobs->map(
                    static function (Job $job) {
                        return Factory::get($job)->threads();
                    }
                )->max());
        } catch (Throwable) {
        }

        return 1;
    }

    /**
     * Get the versions of the databases used by the system to perform the annotation
     *
     * @return array
     */
    public function dbVersions(): array
    {
        return Cache::remember(
            'dbVersions',
            now()->addDay(),
            static function () {
                $versions = [];
                $fp = @fopen(config('oncoreport.db_versions'), 'rb');
                if ($fp) {
                    fgetcsv($fp, separator: "\t"); // skip header
                    while ($line = fgetcsv($fp, separator: "\t")) {
                        $versions[] = [
                            'name'          => $line[0],
                            'version'       => $line[1],
                            'download_date' => $line[2],
                        ];
                    }
                    @fclose($fp);
                }
                $fp = @fopen(config('oncoreport.cosmic_version'), 'rb');
                if ($fp) {
                    $line = fgetcsv($fp, separator: "\t");
                    $versions[] = [
                        'name'          => $line[0],
                        'version'       => $line[1],
                        'download_date' => $line[2],
                    ];
                }

                return $versions;
            }
        );
    }

    /**
     * Transforms this object in an array
     *
     * @return array
     */
    public function toArray(): array
    {
        $containerVersionData = Utils::containerVersionData();

        return [
            'data' => [
                'containerVersion'       => $containerVersionData["version_string"] ?? "Unknown",
                'containerVersionNumber' => $containerVersionData["version"] ?? 0,
                'maxMemory'              => $this->maxMemory(),
                'availableMemory'        => $this->availableMemory(),
                'numCores'               => $this->numCores(),
                'usedCores'              => $this->usedCores(),
                'oncokbTokenStatus'      => $this->oncokbTokenStatus(),
                'dbVersions'             => $this->dbVersions(),
            ],
        ];
    }
}