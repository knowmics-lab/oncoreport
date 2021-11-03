<?php

$tumorsData = [];
$fp = fopen('disease.txt', 'rb');
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
try {
    file_put_contents('icd_to_diseases.json', json_encode($tumorsData, JSON_THROW_ON_ERROR));
} catch (JsonException $e) {
    echo $e;
}