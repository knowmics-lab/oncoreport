<?php

namespace App\Traits;

use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Str;

trait CleanupEsmoTitles
{

    protected ?array $stopwords = null;

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
            'NSCLC'                            => 'Non-Small Cell Lung Cancer',
            'SCLC'                             => 'Small Cell Lung Cancer',
            'ACC'                              => 'Adrenocortical Carcinoma',
            'GEP-NEN'                          => 'Gastroenteropancreatic Neuroendocrine Neoplasm',
            'Hereditary GC'                    => 'Hereditary gastric cancer',
            'NET'                              => 'Neuroendocrine tumor',
            'Loc.'                             => 'Locally',
            'DLBCL'                            => 'diffuse large B-cell lymphoma',
            'PMBCL'                            => 'primary mediastinal B-cell lymphoma',
            'bile duct'                        => 'biliary',
            'leukaemia'                        => 'leukemia',
            'thymoma'                          => 'thymic cancer',
            'thymus'                           => 'thymic',
            'liver'                            => 'hepatocellular',
            'female reproductive endometrioid' => 'endometrial',
            'hepatoblastoma'                   => 'hepatocellular cancer',
            'ö'                                => 'oe',
            '’'                                => '\'',
            '\'\''                             => '\'',
        ];

        return str_ireplace(array_keys($replacements), array_values($replacements), $text);
    }

    /**
     * Remove stopwords from a string
     *
     * @param  string  $text
     *
     * @return string
     */
    protected function removeStopWords(string $text): string
    {
        if ($this->stopwords === null) {
            if (!Cache::has('stopwords')) {
                $this->stopwords = collect(file(resource_path('stopwords.txt')))
                    ->map(fn($w) => trim($w))
                    ->map(fn($w) => '/\b' . preg_quote($w, '/') . '\b/iu')->toArray();
                Cache::put('stopwords', $this->stopwords);
            } else {
                $this->stopwords = Cache::get('stopwords');
            }
        }

        $cleanText = trim(
            preg_replace(
                '/\s+/',
                ' ',
                preg_replace(
                    $this->stopwords,
                    '',
                    Str::slug($text, ' ')
                )
            )
        );

        return str_replace(['b cell', 't cell'], ['b-cell', 't-cell'], $cleanText);
    }

    /**
     * Clean a string by removing abbreviations, stopwords and special characters.
     * It also converts the string in the ASCII charset.
     *
     * @param  string  $text
     *
     * @return string
     */
    protected function cleanString(string $text): string
    {
        return $this->removeStopWords(
            strtolower(mb_convert_encoding($this->handleAbbreviation($text), 'ASCII'))
        );
    }

}