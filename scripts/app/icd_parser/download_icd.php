<?php

require_once __DIR__ . '/vendor/autoload.php';

use GuzzleHttp\Client;
use GuzzleHttp\Exception\GuzzleException;

$icdVersion = trim(file_get_contents(__DIR__ . '/icd_version.txt'));
$icdToDiseases = [];
try {
    $icdToDiseases = json_decode(file_get_contents(__DIR__ . '/icd_to_diseases.json'), true, 512, JSON_THROW_ON_ERROR);
} catch (JsonException $e) {
    echo $e;
    exit(1);
}

$uri = 'http://localhost:8088/icd/release/11/' . $icdVersion . '/mms';
$baseUri = 'http://localhost:8088/icd/release/11/' . $icdVersion . '/mms/%s';

$headers = [
    'Accept'          => 'application/json',
    'Accept-Language' => 'en',
    'API-Version'     => 'v2',
];

/*
PA00–PL2Z  External causes of morbidity or mortality
QA00–QF4Z  Factors influencing health status or contact with health services
VA00–VC50  Supplementary section for functioning assessment (in line with WHO-DAS 2)
X...–X...  Extension Codes ("terminology component" of ICD-11)
*/

function processChildren(
    array $child,
    string $baseUri,
    Client $client,
    array $headers,
    mixed $fp,
    int &$count,
    array &$icdToDiseases
): void {
    $uris = array_filter(
        array_map(
            static fn($d) => (!is_array($d) ? null : $d[count($d) - 1]),
            array_map(
                static fn($u) => explode('/mms/', $u),
                $child ?? []
            )
        )
    );
    foreach ($uris as $u) {
        retrieveCode(sprintf($baseUri, $u), $client, $headers, $fp, $baseUri, $count, $icdToDiseases);
    }
}

function retrieveCode(
    string $uri,
    Client $client,
    array $headers,
    mixed $fp,
    string $baseUri,
    int &$count,
    array &$icdToDiseases
) {
    ++$count;
    if ($count % 100 === 0) {
        echo "Processed url: " . $count . "\r";
    }
    try {
        $response = $client->request('GET', $uri, [
            'headers' => $headers,
        ]);
        $code = $response->getStatusCode();
        if ($code >= 200 && $code <= 300) {
            $output = json_decode($response->getBody(), true, 512, JSON_THROW_ON_ERROR);
            if (isset($output['parent']) && is_array($output['parent'])) {
                $kind = $output['classKind'] ?? '';
                if ($kind === 'category' && !isset($output['child'])) {
                    $icdCode = $output['code'] ?? '';
                    $title = str_replace(' ', ' ', $output['title']['@value'] ?? '');
                    if (!empty($icdCode) && !empty($title) && !preg_match('/^P|Q|S|V/A', $icdCode)) {
                        if (isset($icdToDiseases[$icdCode])) {
                            foreach ($icdToDiseases[$icdCode]['dbName'] as $name) {
                                fprintf(
                                    $fp,
                                    "%s\t%s\t%s\t%d\t%d\n",
                                    $name,
                                    $title,
                                    $icdCode,
                                    $icdToDiseases[$icdCode]['supportedCategory'] ? 1 : 0,
                                    $icdToDiseases[$icdCode]['general'] ? 1 : 0
                                );
                            }
                            $icdToDiseases['__RECORDED__'][] = $icdCode;
                        } else {
                            fprintf($fp, "%s\t%s\t%s\t%d\t%d\n", $title, $title, $icdCode, 0, 0);
                        }
                    }
                }
                if (isset($output['child'])) {
                    processChildren($output['child'], $baseUri, $client, $headers, $fp, $count, $icdToDiseases);
                }
            } else {
                processChildren($output['child'], $baseUri, $client, $headers, $fp, $count, $icdToDiseases);
            }
        } else {
            echo "Status code: " . $code . "\n";
            exit(1);
        }
    } catch (GuzzleException $e) {
        echo $e->getCode();
        echo $e;
        echo "Count = $count";
        exit(1);
    } catch (JsonException $e) {
        echo $e;
        echo "Count = $count";
        exit(1);
    }
}


try {
    $client = new Client();
    $fp = fopen(__DIR__ . '/icd11_diseases.txt', 'wb');
    fprintf($fp, "Disease_database_name\tICD-11_name\tICD-11_Code\tIsTumor\tIs_General_category\n");
    $count = 0;
    $icdToDiseases['__RECORDED__'] = [];
    retrieveCode($uri, $client, $headers, $fp, $baseUri, $count, $icdToDiseases);
    echo "\n\n";
    $recorded = $icdToDiseases['__RECORDED__'];
    unset($icdToDiseases['__RECORDED__']);
    $missingKeys = array_diff(array_keys($icdToDiseases), $recorded);
    foreach ($missingKeys as $key) {
        foreach ($icdToDiseases[$key]['dbName'] as $name) {
            fprintf(
                $fp,
                "%s\t%s\t%s\t%d\t%d\n",
                $name,
                $name,
                $key,
                $icdToDiseases[$key]['supportedCategory'] ? 1 : 0,
                $icdToDiseases[$key]['general'] ? 1 : 0
            );
        }
    }
    fclose($fp);
} catch (Exception | Error $e) {
    echo $e;
    exit(1);
}