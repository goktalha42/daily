<?php
declare(strict_types=1);

require_once __DIR__ . '/auth.php';

header('Content-Type: application/json; charset=utf-8');
header('Cache-Control: no-store');

if (!isAdminLoggedIn()) {
    http_response_code(401);
    echo json_encode(['status' => 'error', 'message' => 'Oturumunuz sona erdi. Lütfen tekrar giriş yapın.']);
    exit;
}

$method = $_SERVER['REQUEST_METHOD'] ?? 'GET';
if (in_array($method, ['POST', 'PUT', 'PATCH', 'DELETE'], true)) {
    $csrfHeader = (string) ($_SERVER['HTTP_X_CSRF_TOKEN'] ?? '');
    if ($csrfHeader === '' || !hash_equals(getAdminCsrfToken(), $csrfHeader)) {
        http_response_code(403);
        echo json_encode(['status' => 'error', 'message' => 'Güvenlik (CSRF) doğrulaması başarısız.']);
        exit;
    }
}

$endpoint = ltrim((string) ($_GET['endpoint'] ?? ''), '/');
$allowedPattern = '#^(calendar|generate-year|day/\d{4}-\d{2}-\d{2}(/(meta|regenerate|queens|pinpoint|crossclimb|tango|zip_path|patches))?)$#';
if ($endpoint === '' || !preg_match($allowedPattern, $endpoint)) {
    http_response_code(400);
    echo json_encode(['status' => 'error', 'message' => 'Geçersiz admin uç noktası.']);
    exit;
}

$cfg = loadAdminConfig();
$query = $_GET;
unset($query['endpoint']);
$qs = http_build_query($query);
$url = rtrim((string) $cfg['vps_admin_api_base'], '/') . '/' . $endpoint . ($qs !== '' ? '?' . $qs : '');

$ch = curl_init($url);
curl_setopt($ch, CURLOPT_CUSTOMREQUEST, $method);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_TIMEOUT, 30);
curl_setopt($ch, CURLOPT_HTTPHEADER, [
    'Accept: application/json',
    'Content-Type: application/json',
    'X-Admin-Secret: ' . $cfg['admin_api_secret'],
]);

if (in_array($method, ['POST', 'PUT', 'PATCH'], true)) {
    $raw = file_get_contents('php://input');
    if ($raw !== false && $raw !== '') {
        curl_setopt($ch, CURLOPT_POSTFIELDS, $raw);
    }
}

$res = curl_exec($ch);
$code = (int) curl_getinfo($ch, CURLINFO_HTTP_CODE);
$err = curl_error($ch);
curl_close($ch);

if ($res === false) {
    http_response_code(502);
    echo json_encode(['status' => 'error', 'message' => 'VPS sunucusuna ulaşılamadı: ' . $err]);
    exit;
}

http_response_code($code > 0 ? $code : 200);
echo $res;

