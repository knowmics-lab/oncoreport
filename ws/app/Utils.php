<?php
/**
 * Oncoreport Web Service
 *
 * @author S. Alaimo, Ph.D. <alaimos at gmail dot com>
 */

namespace App;

use App\Exceptions\IgnoredException;
use App\Exceptions\ProcessingJobException;
use App\Http\Services\SystemInfoService;
use Exception;
use Illuminate\Http\Resources\Json\JsonResource;
use JsonException;
use RecursiveDirectoryIterator;
use RecursiveIteratorIterator;
use SplFileInfo;
use Symfony\Component\Process\Exception\ProcessFailedException;
use Symfony\Component\Process\Process;
use ZipArchive;

final class Utils
{

    public const IGNORED_ERROR_CODE = '===IGNORED===';

    public const VALID_GENOMES = ['hg19', 'hg38'];

    public const VALID_FILTER_OPERATORS = ['lt' => '<', 'lte' => '<=', 'gt' => '>', 'gte' => '>=',];

    public const TUMOR_ONLY_TYPE = 'tumor-only';

    public const TUMOR_NORMAL_TYPE = 'tumor-vs-normal';

    private static array|null $currentVersionCache = null;
    private static array|null $containerVersionCache = null;

    /**
     * Runs a shell command and checks for successful completion of execution
     *
     * @param  array  $command
     * @param  string|null  $cwd
     * @param  int|null  $timeout
     * @param  callable|null  $callback
     *
     * @return string|null
     */
    public static function runCommand(
        array $command,
        ?string $cwd = null,
        ?int $timeout = null,
        ?callable $callback = null
    ): ?string {
        $process = new Process($command, $cwd, null, null, $timeout);
        $process->run($callback);
        if (!$process->isSuccessful()) {
            throw new ProcessFailedException($process);
        }

        return $process->getOutput();
    }

    /**
     * Map command exception to message
     *
     * @param  \Symfony\Component\Process\Exception\ProcessFailedException  $e
     * @param  array  $errorCodeMap
     *
     * @return \Exception
     */
    public static function mapCommandException(
        ProcessFailedException $e,
        array $errorCodeMap = []
    ): Exception {
        $code = $e->getProcess()->getExitCode();
        if (isset($errorCodeMap[$code])) {
            if ($errorCodeMap[$code] === self::IGNORED_ERROR_CODE) {
                return new IgnoredException($code, $code);
            }

            return new ProcessingJobException($errorCodeMap[$code], $code, $e);
        }

        return new ProcessingJobException($e->getMessage(), $code, $e);
    }

    /**
     * Build a zip archive from a folder
     *
     * @param  string  $inputFolder
     * @param  string  $zipArchive
     *
     * @return bool
     */
    public static function makeZipArchive(string $inputFolder, string $zipArchive): bool
    {
        $rootPath = realpath($inputFolder);
        if (!file_exists($rootPath) && !is_dir($rootPath)) {
            return false;
        }
        $zip = new ZipArchive();
        $zip->open($zipArchive, ZipArchive::CREATE | ZipArchive::OVERWRITE);
        /** @var SplFileInfo[] $files */
        $files = new RecursiveIteratorIterator(
            new RecursiveDirectoryIterator($rootPath),
            RecursiveIteratorIterator::LEAVES_ONLY
        );
        foreach ($files as $file) {
            if (!$file->isDir()) {
                $filePath = $file->getRealPath();
                $relativePath = substr($filePath, strlen($rootPath) + 1);
                $zip->addFile($filePath, $relativePath);
            }
        }
        $zip->close();

        return true;
    }

    /**
     * Recursively set chmod
     *
     * @param  string  $inputFolder
     * @param  int  $mode
     * @param  int  $dirMode
     *
     * @return bool
     */
    public static function recursiveChmod(string $inputFolder, int $mode = 0777, int $dirMode = 0777): bool
    {
        $rootPath = realpath($inputFolder);
        if (!file_exists($rootPath) && !is_dir($rootPath)) {
            return false;
        }
        $files = new RecursiveIteratorIterator(new RecursiveDirectoryIterator($rootPath));
        foreach ($files as $file) {
            @chmod($file->getRealPath(), $mode);
        }
        @chmod($rootPath, $dirMode);

        return true;
    }

    /**
     * Flatten a resource object removing data and links sections
     *
     * @param  \Illuminate\Http\Resources\Json\JsonResource  $resource
     * @param  \Illuminate\Http\Request  $request
     *
     * @return array
     */
    public static function flattenResource(JsonResource $resource, $request): array
    {
        $resArray = $resource->toArray($request);
        if (isset($resArray['data'])) {
            $tmpArray = $resArray['data'];
            if (isset($resArray['links']) && is_array($resArray['links'])) {
                foreach ($resArray['links'] as $key => $link) {
                    $tmpArray["{$key}_link"] = $link;
                }
            }

            return $tmpArray;
        }

        return $resArray;
    }

    /**
     * Checks if the admin must run the setup script
     *
     * @return bool
     */
    public static function isSetupNeeded(): bool
    {
        return config('oncoreport.cloud_env') && !file_exists(storage_path('app/cosmic/.setup_done'));
    }

    public static function isUpdateNeeded(): bool
    {
        return config('oncoreport.cloud_env') && (new SystemInfoService())->isUpdateNeeded();
    }

    public static function containerVersionFilePath(): string
    {
        return config('oncoreport.databases_path').'/container_version.json';
    }

    public static function currentVersionFilePath(): string
    {
        return storage_path('app/version_number');
    }

    public static function containerVersionData(): array
    {
        if (self::$containerVersionCache === null) {
            self::$containerVersionCache = self::readJsonData(self::containerVersionFilePath());
        }

        return self::$containerVersionCache;
    }

    public static function currentVersionData(): array
    {
        if (self::$currentVersionCache === null) {
            self::$currentVersionCache = self::readJsonData(self::currentVersionFilePath());
        }

        return self::$currentVersionCache;
    }

    public static function containerVersion(): int
    {
        $containerVersionData = self::containerVersionData();

        return $containerVersionData['version'] ?? 0;
    }

    public static function currentVersion(): int
    {
        $currentVersionData = self::currentVersionData();

        return $currentVersionData['version'] ?? 0;
    }

    public static function readJsonData(string $path): array
    {
        if (!file_exists($path)) {
            return [];
        }
        try {
            $data = json_decode(file_get_contents($path), true, 512, JSON_THROW_ON_ERROR);
        } catch (JsonException) {
            return [];
        }
        if (!is_array($data)) {
            return [];
        }

        return $data;
    }

}
