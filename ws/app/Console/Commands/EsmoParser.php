<?php
/**
 * Oncoreport Web Service
 *
 * @author S. Alaimo, Ph.D. <alaimos at gmail dot com>
 */

namespace App\Console\Commands;

use App\Models\Disease;
use App\Traits\CleanupEsmoTitles;
use Error;
use Exception;
use Illuminate\Console\Command;
use JsonException;

class EsmoParser extends Command
{
    use CleanupEsmoTitles;

    private const ESMO_PATH = 'app/esmo/';
    private const IDX_URL   = 'https://interactiveguidelines.esmo.org/esmo-web-app/media/data/EN/SearchFiles/idx.json';
    private const TOC_URL   = 'https://interactiveguidelines.esmo.org/esmo-web-app/media/data/EN/TOCJson/guidelinesTOC.json';

    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'esmo:parse {disease : The name of the patient disease} {output : The output folder}';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Parse esmo guidelines given the cancer type building the HTML file needed for the report.';

    /**
     * Download a file or uses cached content if download is not working.
     * If the previously downloaded file does not exist than returns null.
     *
     * @param  string  $url  The file URL
     * @param  string  $outputPath  The output path
     *
     * @return string|null
     */
    protected static function downloadFile(string $url, string $outputPath): ?string
    {
        if (file_exists($outputPath)) {
            return $outputPath;
        }
        try {
            $context = stream_context_create(
                [
                    "ssl" => [
                        "verify_peer"      => false,
                        "verify_peer_name" => false,
                    ],
                ]
            );
            $tmpOutputFile = tempnam("/tmp", "downloaded_file");
            if (file_put_contents($tmpOutputFile, file_get_contents($url, context: $context)) !== false) {
                if (file_exists($outputPath)) {
                    unlink($outputPath);
                }
                rename($tmpOutputFile, $outputPath);
            }
        } catch (Error|Exception) {
        }
        if (file_exists($outputPath)) {
            return $outputPath;
        }

        return null;
    }

    /**
     * Download ESMO guidelines index
     *
     * @return array
     */
    protected static function downloadEsmo(): array
    {
        $esmoPath = storage_path(self::ESMO_PATH);
        if (!file_exists($esmoPath) && !mkdir($esmoPath, 0777, true) && !is_dir($esmoPath)) {
            return [null, null];
        }

        return [
            self::downloadFile(self::TOC_URL, storage_path(self::ESMO_PATH.'toc.json')),
            self::downloadFile(self::IDX_URL, storage_path(self::ESMO_PATH.'idx.json')),
        ];
    }

    /**
     * Read a json file
     *
     * @throws \JsonException
     */
    protected static function readJson(string $file): array
    {
        return json_decode(file_get_contents($file), true, 512, JSON_THROW_ON_ERROR);
    }

    protected function findEsmoGuidelines(string $doid, array &$toc): array
    {
        $tumorsToEsmoFile = storage_path(self::ESMO_PATH.'tumors_to_esmo.tsv');
        if (!file_exists($tumorsToEsmoFile)) {
            $this->call('esmo:match');
        }
        $guidelines = [];
        $handle = fopen($tumorsToEsmoFile, 'rb');
        if ($handle) {
            while (($line = fgetcsv($handle, separator: "\t")) !== false) {
                if ($line[0] === $doid) {
                    $guidelines = array_map(
                        static fn($g) => strtolower(trim($g)),
                        explode(';', $line[2])
                    );
                    break;
                }
            }
            fclose($handle);
        }

        return array_filter(
            $toc,
            static fn($d) => in_array(strtolower(trim($d['guidelineName'])), $guidelines, true)
        );
    }

    /**
     * Find all arguments from the ESMO guideline
     *
     * @param  string  $cmsID
     * @param  array  $idx
     *
     * @return array
     */
    protected function findRelatedArguments(string $cmsID, array &$idx): array
    {
        return array_values(array_filter($idx, static fn($d) => str_starts_with($d['jumpto'], $cmsID)));
    }

    /**
     * Execute the console command.
     *
     * @return mixed
     */
    public function handle(): int
    {
        $doid = $this->argument('disease');
        $diseaseName = Disease::where('doid', $doid)->firstOrFail(['name'])->name;
        $outputDir = $this->argument('output');
        if (!file_exists($outputDir) && !mkdir($outputDir, 0777, true) && !is_dir($outputDir)) {
            $this->error('Unable to create output directory.');

            return 101;
        }
        $this->info('Downloading ESMO guidelines index');
        [$tocPath, $idxPath] = self::downloadEsmo();
        if ($tocPath === null || $idxPath === null) {
            $this->error('Unable to download ESMO guidelines!');

            return 102;
        }
        try {
            $this->info('Processing guidelines for '.$diseaseName);
            $toc = self::readJson($tocPath);
            $matches = $this->findEsmoGuidelines($doid, $toc);
            $idx = self::readJson($idxPath);
            $matches = array_filter(
                array_map(
                    fn($d) => $d + ['args' => $this->findRelatedArguments($d['cmsID'], $idx)],
                    $matches
                ),
                static fn($d) => count($d['args']) > 0
            );
            if (count($matches) === 0) {
                $this->warn('No matching diseases found in the ESMO guideline.');
            }
            if (file_put_contents(
                    $outputDir.'/esmo_parsed.html',
                    view('esmo.index', compact('matches'))->render()
                ) === false) {
                $this->error('Unable to render ESMO index file.');

                return 103;
            }
            $this->info("Processing completed!");
        } catch (JsonException $e) {
            $this->error($e->getMessage());

            return 104;
        }

        return 0;
    }
}
