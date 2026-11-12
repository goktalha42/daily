<?php
declare(strict_types=1);

// Hostinger (HTTPS) -> Ubuntu VPS (HTTP) güvenli aynı alan adı proxy'si.
// /api/v1/admin/* yolları buradan kesinlikle engellenir (sadece loginli /admin backend'i kullanır).

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    header('Access-Control-Allow-Origin: https://' . ($_SERVER['HTTP_HOST'] ?? 'zuhtuapp.cyboros.com'));
    header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
    header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Device-Id, Accept');
    http_response_code(204);
    exit;
}

$path = ltrim((string) ($_GET['path'] ?? ''), '/');
if ($path === '' || preg_match('#(^|/)admin(/|$)#i', $path) || str_contains($path, '..')) {
    header('Content-Type: application/json; charset=utf-8');
    http_response_code(403);
    echo json_encode(['status' => 'error', 'message' => 'Erişim engellendi.']);
    exit;
}

$query = $_GET;
unset($query['path']);
$qs = http_build_query($query);

$targetUrl = 'http://2.56.109.165/api/' . $path . ($qs !== '' ? '?' . $qs : '');

$ch = curl_init($targetUrl);
$method = $_SERVER['REQUEST_METHOD'] ?? 'GET';
curl_setopt($ch, CURLOPT_CUSTOMREQUEST, $method);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_TIMEOUT, 15);
curl_setopt($ch, CURLOPT_FOLLOWLOCATION, false);

$forwardHeaders = ['Accept: application/json'];
if (!empty($_SERVER['CONTENT_TYPE'])) {
    $forwardHeaders[] = 'Content-Type: ' . $_SERVER['CONTENT_TYPE'];
}
if (!empty($_SERVER['HTTP_AUTHORIZATION'])) {
    $forwardHeaders[] = 'Authorization: ' . $_SERVER['HTTP_AUTHORIZATION'];
}
if (!empty($_SERVER['HTTP_X_DEVICE_ID'])) {
    $forwardHeaders[] = 'X-Device-Id: ' . $_SERVER['HTTP_X_DEVICE_ID'];
}
curl_setopt($ch, CURLOPT_HTTPHEADER, $forwardHeaders);

if (in_array($method, ['POST', 'PUT', 'PATCH', 'DELETE'], true)) {
    $rawBody = file_get_contents('php://input');
    if ($rawBody !== false && $rawBody !== '') {
        curl_setopt($ch, CURLOPT_POSTFIELDS, $rawBody);
    }
}

$responseBody = curl_exec($ch);
$httpCode = (int) curl_getinfo($ch, CURLINFO_HTTP_CODE);
$contentType = curl_getinfo($ch, CURLINFO_CONTENT_TYPE) ?: 'application/json; charset=utf-8';
$curlErr = curl_error($ch);
curl_close($ch);

if ($responseBody === false) {
    header('Content-Type: application/json; charset=utf-8');
    http_response_code(502);
    echo json_encode(['status' => 'error', 'message' => 'VPS bağlantısı kurulamadı: ' . $curlErr]);
    exit;
}

header('Content-Type: ' . $contentType);
header('Cache-Control: no-store');
http_response_code($httpCode > 0 ? $httpCode : 200);
echo $responseBody;

