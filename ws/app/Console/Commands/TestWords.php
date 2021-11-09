<?php
/**
 * Oncoreport Web Service
 *
 * @author S. Alaimo, Ph.D. <alaimos at gmail dot com>
 */

namespace App\Console\Commands;

use App\Models\Disease;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Str;
use Throwable;

class TestWords extends Command
{

    private const ESMO_PATH = 'app/esmo/';
    private const IDX_URL   = 'http://interactiveguidelines.esmo.org/esmo-web-app/media/data/EN/SearchFiles/idx.json';
    private const TOC_URL   = 'http://interactiveguidelines.esmo.org/esmo-web-app/media/data/EN/TOCJson/guidelinesTOC.json';

    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'test:words';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Parse all diseases to test for words distribution.';

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
            $stopwords = collect(file(resource_path('stopwords.txt')))
                ->map(fn($w) => trim($w))
                ->map(fn($w) => '/\b' . preg_quote($w, '/') . '\b/iu')->toArray();
            Cache::put('stopwords', $stopwords);
        } else {
            $stopwords = Cache::get('stopwords');
        }

        $cleanText = trim(
            preg_replace(
                '/\s+/',
                ' ',
                preg_replace(
                    $stopwords,
                    '',
                    Str::slug($text, ' ')
                )
            )
        );
        $splitText = array_filter(preg_split('/\s+/', $cleanText));
        asort($splitText);

        return implode(' ', $splitText);
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
     * Execute the console command.
     *
     * @return mixed
     */
    public function handle(): int
    {
        try {
            [$tocPath,] = self::downloadEsmo();
            $toc = self::readJson($tocPath);
            $disease =
                Disease::where('tumor', 1)
                       ->get()
                       ->map(function (Disease $d) use (&$toc) {
                           $m = $this->findBestMatch($d->name, $toc);
                           $guidelines = array_map(static fn($d) => $d['guidelineName'], $m);

                           return [
                               $d->icd_code,
                               $d->name,
                               implode(';', $guidelines),
                           ];
                       });
            $fp = fopen('tumors_to_ecmo.txt', 'wb');
            fputcsv($fp, ['ICD_Code', 'Name', 'ECMO_Guidelines_Titles'], separator: "\t");
            foreach ($disease as $d) {
                fputcsv($fp, $d, separator: "\t");
            }
            fclose($fp);
            $fp = fopen('ecmo_titles.txt', 'wb');
            foreach ($toc as $t) {
                fwrite($fp, $t['guidelineName'] . "\n");
            }
            fclose($fp);
        } catch (Throwable $e) {
            $this->error($e);

            return 1;
        }

        return 0;
    }
}
