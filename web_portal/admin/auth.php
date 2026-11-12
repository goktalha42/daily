<?php
declare(strict_types=1);

function loadAdminConfig(): array
{
    static $cfg = null;
    if ($cfg !== null) {
        return $cfg;
    }
    $path = __DIR__ . '/config.php';
    if (!file_exists($path)) {
        http_response_code(500);
        exit('Admin yapılandırması (config.php) bulunamadı.');
    }
    $cfg = require $path;
    return $cfg;
}

function startAdminSession(): void
{
    if (session_status() === PHP_SESSION_ACTIVE) {
        return;
    }
    $isHttps = (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off')
        || (($_SERVER['HTTP_X_FORWARDED_PROTO'] ?? '') === 'https');
    session_set_cookie_params([
        'lifetime' => 86400 * 7,
        'path' => '/admin',
        'secure' => $isHttps,
        'httponly' => true,
        'samesite' => 'Lax',
    ]);
    session_start();
}

function isAdminLoggedIn(): bool
{
    startAdminSession();
    return !empty($_SESSION['zuhtu_admin_logged_in']);
}

function getAdminCsrfToken(): string
{
    startAdminSession();
    if (empty($_SESSION['zuhtu_admin_csrf'])) {
        $_SESSION['zuhtu_admin_csrf'] = bin2hex(random_bytes(24));
    }
    return (string) $_SESSION['zuhtu_admin_csrf'];
}

function verifyAdminLogin(string $username, string $password): bool
{
    $cfg = loadAdminConfig();
    $expectedUser = (string) ($cfg['admin_username'] ?? 'admin');
    $hash = (string) ($cfg['admin_password_hash'] ?? '');
    if (!hash_equals($expectedUser, trim($username))) {
        return false;
    }
    if ($hash === '' || !password_verify($password, $hash)) {
        return false;
    }
    startAdminSession();
    session_regenerate_id(true);
    $_SESSION['zuhtu_admin_logged_in'] = true;
    $_SESSION['zuhtu_admin_user'] = $expectedUser;
    getAdminCsrfToken();
    return true;
}

function logoutAdmin(): void
{
    startAdminSession();
    $_SESSION = [];
    if (ini_get('session.use_cookies')) {
        $params = session_get_cookie_params();
        setcookie(session_name(), '', time() - 42000, $params['path'], $params['domain'] ?? '', $params['secure'], $params['httponly']);
    }
    session_destroy();
}

