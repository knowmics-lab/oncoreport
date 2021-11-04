<?php

try {
    $tumorsData = [];
    $fp = fopen(__DIR__ . '/disease.txt', 'rb');
    fgetcsv($fp, separator: "\t"); // Skip first line
    while (($line = fgetcsv($fp, separator: "\t")) !== false) {
        if (count($line) >= 5) {
            $dbName = mb_convert_encoding($line[0], 'UTF-8', 'UTF-8');
            $icdCode = array_map('trim', explode(',', $line[2]));
            $supportedCategory = (int)$line[3] === 1;
            $general = (int)$line[4] === 1;
            if ($supportedCategory || $general) {
                foreach ($icdCode as $code) {
                    if (!isset($tumorsData[$code])) {
                        $tumorsData[$code] = [
                            'dbName'            => [],
                            'supportedCategory' => $supportedCategory,
                            'general'           => $general,
                        ];
                    }
                    $tumorsData[$code]['dbName'][] = $dbName;
                }
            }
        }
    }
    fclose($fp);

    file_put_contents(__DIR__ . '/icd_to_diseases.json', json_encode($tumorsData, JSON_THROW_ON_ERROR));
} catch (JsonException | Exception | Error $e) {
    echo $e;
    exit(1);
}