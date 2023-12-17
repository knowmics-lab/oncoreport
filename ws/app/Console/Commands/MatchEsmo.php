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
use Illuminate\Support\Collection;
use Throwable;

class MatchEsmo extends Command
{
    use CleanupEsmoTitles;

    private const ESMO_PATH = 'app/esmo/';
    private const IDX_URL   = 'http://interactiveguidelines.esmo.org/esmo-web-app/media/data/EN/SearchFiles/idx.json';
    private const TOC_URL   = 'http://interactiveguidelines.esmo.org/esmo-web-app/media/data/EN/TOCJson/guidelinesTOC.json';

    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'esmo:match';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Matches the ESMO guidelines to DO diseases.';

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
        } catch (Error|Exception) {
        }
        if (file_exists($outputPath)) {
            return $outputPath;
        }

        return null;
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
     * Filters the ESMO table of contents to only include disease guidelines
     *
     * @param  array  $toc
     *
     * @return array
     */
    protected function filterToc(array $toc): array
    {
        $skip = file(resource_path('esmo_skip.txt'), FILE_IGNORE_NEW_LINES);

        return array_filter($toc, static fn($d) => !in_array($d['guidelineName'], $skip, true));
    }

    /**
     * Checks for false matches between two string.
     * False matches are similar words that must be considered as different.
     *
     * @param  string  $string1
     * @param  string  $string2
     *
     * @return bool
     */
    protected function checkFalseMatches(string $string1, string $string2): bool
    {
        $falseMatches = [
            'leukemia' => 'lymphoma',
            't-cell'   => 'b-cell',
        ];
        foreach ($falseMatches as $key => $value) {
            if (str_contains($string1, $key) && str_contains($string2, $value)) {
                return true;
            }
            if (str_contains($string2, $key) && str_contains($string1, $value)) {
                return true;
            }
        }

        return false;
    }

    /**
     * Checks if a string contains all words from another string.
     * The second string must be contained in the first one, but not vice-versa.
     *
     * @param  string  $string
     * @param  string  $words
     *
     * @return bool
     */
    protected function stringContainsAllWords(string $string, string $words): bool
    {
        if ($this->checkFalseMatches($string, $words)) {
            return false;
        }
        $words = array_map(static fn($w) => trim($w), explode(' ', $words));
        $string = array_map(static fn($w) => trim($w), explode(' ', $string));

        if (count($words) > count($string)) {
            return count(array_intersect($string, $words)) === count($string);
        }

        return count(array_intersect($words, $string)) === count($words);
    }

    /**
     * Finds all ESMO guidelines that might match a given string
     *
     * @param  array  $allGuidelines
     * @param  string  $disease
     * @param  array  $toc
     *
     * @return array
     */
    protected function findGuidelinesMatchingOfAllWords(array $allGuidelines, string $disease, array $toc): array
    {
        $foundGuidelines = [];
        foreach ($allGuidelines as $i => $string) {
            if ($this->stringContainsAllWords($string, $disease)) {
                $foundGuidelines[] = $toc[$i];
            }
        }

        return $foundGuidelines;
    }

    /**
     * Finds all ESMO guidelines that might match a given disease
     *
     * @param  string  $disease
     * @param  array  $toc
     *
     * @return array
     */
    protected function findBestMatch(string $disease, array $toc): array
    {
        $disease = $this->cleanString($disease);
        if (empty($disease)) {
            return [];
        }
        $guidelines = array_map(fn($d) => $this->cleanString($d['guidelineName']), $toc);

        return $this->findGuidelinesMatchingOfAllWords($guidelines, $disease, $toc);
    }

    /**
     * Reads the list of DO parents in the ontology graph from a file
     * @return array
     */
    protected function readParents(): array
    {
        $handle = fopen(config('oncoreport.databases_path').'/do_parents.tsv', 'rb');
        $header = fgetcsv($handle, separator: "\t");
        $doids = [];
        $data = [];
        while ($row = fgetcsv($handle, separator: "\t")) {
            $tmp = array_combine($header, $row);
            $tmp['parents'] = explode(';', $tmp['parents']);
            $data[] = $tmp;
            $doids[] = $tmp['doid'];
        }

        return array_combine($doids, $data);
    }

    /**
     * Recursively finds the first filled parent of a given disease.
     * A set of excluded parents can be provided as a parameter.
     *
     * @param  string  $childDoid
     * @param  \Illuminate\Support\Collection  $diseases
     * @param  array  $parents
     * @param  array  $exclude
     *
     * @return string|null
     */
    protected function findFirstFilledParent(
        string $childDoid,
        Collection $diseases,
        array $parents,
        array $exclude = []
    ): ?string {
        if (!isset($parents[$childDoid])) {
            return null;
        }
        $parentsList = $parents[$childDoid]['parents'];
        foreach ($parentsList as $parentDoid) {
            if ($diseases->has($parentDoid) && !in_array($parentDoid, $exclude, true)) {
                $parentGuidelines = $diseases[$parentDoid][2];
                if (!empty($parentGuidelines)) {
                    return $parentDoid;
                }
                $parentParent = $this->findFirstFilledParent($parentDoid, $diseases, $parents, $exclude);
                if ($parentParent !== null) {
                    return $parentParent;
                }
            }
        }

        return null;
    }

    /**
     * Fill child guidelines with parent ones, by checking for false matches.
     * The function returns if the disease has been filled with parent guidelines.
     *
     * @param  string  $child
     * @param  string  $parent
     * @param  \Illuminate\Support\Collection  $diseases
     *
     * @return bool
     */
    protected function fillChildWithParent(string $child, string $parent, Collection $diseases): bool
    {
        $parentGuidelines = explode(';', $diseases[$parent][2]);
        $childDisease = $diseases[$child];
        $childDiseaseName = $this->cleanString($childDisease[1]);
        $parentGuidelines = array_unique(
            array_filter(
                $parentGuidelines,
                fn($g) => !$this->checkFalseMatches($this->cleanString($g), $childDiseaseName)
            )
        );
        $gl = $childDisease[2] = implode(';', $parentGuidelines);
        $diseases[$child] = $childDisease;

        return !empty($gl);
    }


    /**
     * Execute the console command.
     *
     * @return mixed
     */
    public function handle(): int
    {
        try {
            $this->info('Downloading ESMO TOC...');
            [$tocPath,] = self::downloadEsmo();
            $toc = $this->filterToc(self::readJson($tocPath));
            $this->info('Reading DO parents...');
            $parents = $this->readParents();
            $this->info('Processing diseases...');
            $disease =
                Disease::where('tumor', 1)
                       ->get()
                       ->map(
                           function (Disease $d) use (&$toc) {
                               $m = $this->findBestMatch($d->name, $toc);
                               $guidelines = array_unique(array_map(static fn($d) => $d['guidelineName'], $m));

                               return [
                                   $d->doid,
                                   $d->name,
                                   implode(';', $guidelines),
                               ];
                           }
                       )
                       ->keyBy(fn($d) => $d[0]);
            $this->info('Trying to fill empty children...');
            foreach ($disease as $d) {
                $guidelines = $d[2];
                if (empty($guidelines)) {
                    $exclude = [];
                    while (($parent = $this->findFirstFilledParent($d[0], $disease, $parents, $exclude)) !== null) {
                        if ($this->fillChildWithParent($d[0], $parent, $disease)) {
                            break;
                        }
                        $exclude[] = $parent;
                    }
                }
            }
            $this->info('Writing output file...');
            $outputFile = storage_path(self::ESMO_PATH.'tumors_to_esmo.tsv');
            $fp = fopen($outputFile, 'wb');
            fputcsv($fp, ['DOID', 'Name', 'ESMO_Guidelines_Titles'], separator: "\t");
            foreach ($disease as $d) {
                fputcsv($fp, $d, separator: "\t");
            }
            fclose($fp);
            @chmod($outputFile, 0777);
            $this->info('Done!');
//            $fp = fopen('esmo_titles.txt', 'wb');
//            foreach ($toc as $t) {
//                fwrite($fp, $t['guidelineName'] . "\n");
//            }
//            fclose($fp);
//            echo "\n";
        } catch (Throwable $e) {
            $this->error($e);

            return 1;
        }

        return 0;
    }
}
