<?php

// docker run -p 80:80 -e acceptLicense=true -e saveAnalytics=false whoicd/icd-api

require_once __DIR__ . '/vendor/autoload.php';

use GuzzleHttp\Client;
use GuzzleHttp\Exception\GuzzleException;

$uri = 'http://localhost/icd/release/11/2021-05/mms';
$baseUri = 'http://localhost/icd/release/11/2021-05/mms/%s';

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
    int &$count
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
        retrieveCode(sprintf($baseUri, $u), $client, $headers, $fp, $baseUri, $count);
    }
}

function retrieveCode(
    string $uri,
    Client $client,
    array $headers,
    mixed $fp,
    string $baseUri,
    int &$count
) {
    ++$count;
    if ($count % 1000 === 0) {
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
                        fprintf($fp, "%s\t%s\n", $icdCode, $title);
                    }
//                    } else {
//                        printf("%s\t%s\n", $icdCode, $title);
//                    }
                }
                if (isset($output['child'])) {
                    processChildren($output['child'], $baseUri, $client, $headers, $fp, $count);
                }
            } else {
                processChildren($output['child'], $baseUri, $client, $headers, $fp, $count);
            }
        } else {
            echo "Status code: " . $code . "\n";
            die();
        }
    } catch (GuzzleException $e) {
        echo $e->getCode();
        echo $e;
        echo "Count = $count";
    } catch (JsonException $e) {
        echo $e;
        echo "Count = $count";
    }
}


$client = new Client();
$fp = fopen('output.tsv', 'wb');
$count = 0;
retrieveCode($uri, $client, $headers, $fp, $baseUri, $count);
echo "\n\n";
fclose($fp);
