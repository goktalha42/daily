<?php

use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    return view('welcome');
});

Route::get('/privacy-policy', function () {
    $privacyFile = base_path('../PRIVACY_POLICY.md');
    $content = file_exists($privacyFile) 
        ? file_get_contents($privacyFile) 
        : 'Gizlilik Politikası yüklenemedi.';
    
    // Basit ve şık HTML sarmalayıcı
    $htmlContent = htmlspecialchars($content);
    return response("<!DOCTYPE html>
<html lang='tr'>
<head>
    <meta charset='UTF-8'>
    <meta name='viewport' content='width=device-width, initial-scale=1.0'>
    <title>Zühtü - Gizlilik Politikası</title>
    <style>
        body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; line-height: 1.6; max-width: 800px; margin: 0 auto; padding: 24px; color: #1e293b; background: #f8fafc; }
        .card { background: #ffffff; padding: 32px; border-radius: 12px; box-shadow: 0 4px 6px -1px rgba(0,0,0,0.1); border: 1px solid #e2e8f0; }
        h1, h2, h3 { color: #0f172a; }
        pre { white-space: pre-wrap; word-wrap: break-word; font-family: inherit; font-size: 15px; }
        a { color: #2563eb; }
    </style>
</head>
<body>
    <div class='card'>
        <pre>{$htmlContent}</pre>
    </div>
</body>
</html>", 200, ['Content-Type' => 'text/html; charset=utf-8']);
});

