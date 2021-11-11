<?php
/**
 * Oncoreport Web Service
 *
 * @author S. Alaimo, Ph.D. <alaimos at gmail dot com>
 */

namespace App\Console\Commands;

use App\Models\Disease;
use Error;
use Exception;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Str;
use JsonException;

class EsmoParser extends Command
{

    private const ESMO_PATH = 'app/esmo/';
    private const IDX_URL   = 'http://interactiveguidelines.esmo.org/esmo-web-app/media/data/EN/SearchFiles/idx.json';
    private const TOC_URL   = 'http://interactiveguidelines.esmo.org/esmo-web-app/media/data/EN/TOCJson/guidelinesTOC.json';

    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'parse:esmo {disease : The name of the patient disease} {output : The output folder}';

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
        try {
            $tmpOutputFile = tempnam("/tmp", "downloaded_file");
            if (file_put_contents($tmpOutputFile, fopen($url, 'rb')) !== false) {
                if (file_exists($outputPath)) {
                    unlink($outputPath);
                }
                rename($tmpOutputFile, $outputPath);
            }
        } catch (Error | Exception) {
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
            self::downloadFile(self::TOC_URL, storage_path(self::ESMO_PATH . 'toc.json')),
            self::downloadFile(self::IDX_URL, storage_path(self::ESMO_PATH . 'idx.json')),
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

    /**
     * Replaces abbreviations with complete text
     *
     * @param  string  $text
     *
     * @return string
     */
    protected function handleAbbreviation(string $text): string
    {
        $replacements = [
            'NSCLC'         => 'Non-Small Cell Lung Cancer',
            'SCLC'          => 'Small Cell Lung Cancer',
            'ACC'           => 'Adrenocortical Carcinoma',
            'GEP-NEN'       => 'Gastroenteropancreatic Neuroendocrine Neoplasm',
            'Hereditary GC' => 'Hereditary gastric cancer',
            'NET'           => 'Neuroendocrine tumor',
            'Loc.'          => 'Locally',
            'DLBCL'         => 'diffuse large B-cell lymphoma',
            'PMBCL'         => 'primary mediastinal B-cell lymphoma',
            'ö'             => 'o',
            '’'             => '\'',
            '\'\''          => '\'',
        ];

        return str_replace(array_keys($replacements), array_values($replacements), $text);
    }

    protected function removeStopWords(string $text): string
    {
        if (!Cache::has('stopwords')) {
            $words = collect(file(resource_path('stopwords.txt')))
                ->map(fn($w) => trim($w))
                ->map(fn($w) => '/\b' . preg_quote($w, '/') . '\b/iu')->toArray();
            Cache::put('stopwords', $words);
        } else {
            $words = Cache::get('stopwords');
        }

        return trim(
            preg_replace(
                '/\s+/',
                ' ',
                preg_replace(
                    $words,
                    '',
                    Str::slug($text, ' ')
                )
            )
        );
    }

    /**
     * Find the best matches in the ESMO guidelines
     *
     * @param  string  $disease
     * @param  array  $toc
     *
     * @return array
     */
    protected function findBestMatch(string $disease, array &$toc): array
    {
        $disease = $this->removeStopWords(strtolower(mb_convert_encoding($disease, 'ASCII')));
        $scoredGuidelines = array_filter(
            array_map(function ($d) use ($disease) {
                $title = $this->removeStopWords(
                    strtolower(mb_convert_encoding($this->handleAbbreviation($d['guidelineName']), 'ASCII'))
                );
                similar_text($disease, $title, $percent);

                return [
                    $d,
                    $title,
                    $percent,
                ];
            }, $toc),
            static fn($d) => str_contains(strtolower($d[1]), $disease) || $d[2] > 50
        );
        usort($scoredGuidelines, static fn($x, $y) => $y[2] - $x[2]);

        return array_map(static fn($d) => $d[0], $scoredGuidelines);
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
        $diseaseName = Disease::where('doid', $this->argument('disease'))->firstOrFail(['name'])->name;
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
            $this->info('Processing guidelines for ' . $diseaseName);
            $toc = self::readJson($tocPath);
            $matches = $this->findBestMatch($diseaseName, $toc);
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
                    $outputDir . '/esmo_parsed.html',
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
