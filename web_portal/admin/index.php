<?php
declare(strict_types=1);

require_once __DIR__ . '/auth.php';

if (($_GET['action'] ?? '') === 'logout' && $_SERVER['REQUEST_METHOD'] === 'POST') {
    $csrf = (string) ($_POST['csrf_token'] ?? '');
    if (hash_equals(getAdminCsrfToken(), $csrf)) {
        logoutAdmin();
    }
    header('Location: /admin/');
    exit;
}

$loginError = null;
if (!isAdminLoggedIn() && $_SERVER['REQUEST_METHOD'] === 'POST') {
    $csrf = (string) ($_POST['csrf_token'] ?? '');
    if (!hash_equals(getAdminCsrfToken(), $csrf)) {
        $loginError = 'Güvenlik doğrulaması başarısız. Sayfayı yenileyip tekrar deneyin.';
    } else {
        $user = (string) ($_POST['username'] ?? '');
        $pass = (string) ($_POST['password'] ?? '');
        if (verifyAdminLogin($user, $pass)) {
            header('Location: /admin/');
            exit;
        }
        $loginError = 'Kullanıcı adı veya şifre hatalı.';
    }
}

$csrfToken = getAdminCsrfToken();
$loggedIn = isAdminLoggedIn();
?>
<!DOCTYPE html>
<html lang="tr">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Zühtü Admin • 365 Günlük Bulmaca Takvimi</title>
  <style>
    :root {
      --paper: #faf8f2;
      --card: #ffffff;
      --ink: #1e293b;
      --muted: #64748b;
      --border: #1e293b;
      --sun: #facc15;
      --blue: #0284c7;
      --green: #16a34a;
      --red: #dc2626;
      --purple: #7c3aed;
    }
    * { box-sizing: border-box; }
    body {
      margin: 0;
      font-family: 'Segoe UI', system-ui, -apple-system, sans-serif;
      background: var(--paper);
      color: var(--ink);
    }
    .sketch-box {
      background: var(--card);
      border: 2px solid var(--border);
      border-radius: 14px;
      box-shadow: 3px 3px 0 var(--border);
    }
    .btn {
      display: inline-flex;
      align-items: center;
      gap: 6px;
      padding: 8px 14px;
      border-radius: 10px;
      border: 2px solid var(--border);
      background: #fff;
      color: var(--ink);
      font-weight: 700;
      font-size: 13px;
      cursor: pointer;
      box-shadow: 2px 2px 0 var(--border);
      text-decoration: none;
    }
    .btn:active { transform: translate(1px, 1px); box-shadow: 1px 1px 0 var(--border); }
    .btn-sun { background: var(--sun); }
    .btn-blue { background: #e0f2fe; color: #0369a1; }
    .btn-red { background: #fee2e2; color: #b91c1c; }
    .btn-sm { padding: 5px 10px; font-size: 12px; }
    input[type="text"], input[type="password"], input[type="number"], input[type="date"], select, textarea {
      width: 100%;
      padding: 8px 10px;
      border: 2px solid var(--border);
      border-radius: 9px;
      font: inherit;
      background: #fff;
      color: var(--ink);
    }
    label { display: block; font-size: 12px; font-weight: 700; margin-bottom: 4px; color: var(--muted); }

    /* Login */
    .login-wrap {
      min-height: 100vh;
      display: grid;
      place-items: center;
      padding: 20px;
    }
    .login-card { width: 100%; max-width: 400px; padding: 28px; }
    .login-card h1 { margin: 0 0 6px; font-size: 26px; }
    .login-card p { margin: 0 0 20px; color: var(--muted); font-size: 14px; }
    .field { margin-bottom: 14px; }
    .alert-err {
      background: #fee2e2;
      border: 2px solid var(--red);
      color: #991b1b;
      padding: 10px 12px;
      border-radius: 10px;
      font-size: 13px;
      font-weight: 600;
      margin-bottom: 14px;
    }

    /* Dashboard */
    .topbar {
      display: flex;
      flex-wrap: wrap;
      align-items: center;
      justify-content: space-between;
      gap: 12px;
      padding: 14px 20px;
      border-bottom: 2px solid var(--border);
      background: #fff;
      position: sticky;
      top: 0;
      z-index: 20;
    }
    .brand { display: flex; align-items: center; gap: 10px; font-weight: 900; font-size: 20px; }
    .brand .tag {
      background: var(--sun);
      border: 2px solid var(--border);
      padding: 2px 9px;
      border-radius: 99px;
      font-size: 12px;
    }
    .topbar-actions { display: flex; flex-wrap: wrap; gap: 8px; align-items: center; }

    .layout {
      display: grid;
      grid-template-columns: 350px 1fr;
      gap: 18px;
      padding: 18px 20px;
      max-width: 1440px;
      margin: 0 auto;
    }
    @media (max-width: 980px) {
      .layout { grid-template-columns: 1fr; }
    }

    .sidebar {
      display: flex;
      flex-direction: column;
      height: calc(100vh - 104px);
      position: sticky;
      top: 84px;
      padding: 14px;
      gap: 10px;
    }
    @media (max-width: 980px) {
      .sidebar { height: 420px; position: static; }
    }
    .filter-row { display: flex; gap: 6px; flex-wrap: wrap; }
    .pill {
      padding: 4px 10px;
      border: 1.5px solid var(--border);
      border-radius: 99px;
      background: #fff;
      font-size: 12px;
      font-weight: 700;
      cursor: pointer;
    }
    .pill.active { background: var(--sun); }
    .day-list { overflow-y: auto; flex: 1; display: flex; flex-direction: column; gap: 8px; padding-right: 4px; }
    .day-item {
      border: 2px solid #cbd5e1;
      border-radius: 11px;
      padding: 9px 11px;
      cursor: pointer;
      background: #fff;
      transition: .12s;
    }
    .day-item:hover { border-color: var(--border); }
    .day-item.active {
      border-color: var(--border);
      background: #fef9c3;
      box-shadow: 2px 2px 0 var(--border);
    }
    .day-item.special { border-left: 5px solid #f59e0b; }
    .day-head { display: flex; justify-content: space-between; align-items: center; font-weight: 800; font-size: 13.5px; }
    .day-sub { font-size: 12px; color: var(--muted); margin-top: 4px; display: flex; flex-wrap: wrap; gap: 6px; }
    .badge {
      display: inline-block;
      padding: 1px 7px;
      border-radius: 99px;
      font-size: 11px;
      font-weight: 800;
      border: 1.5px solid var(--border);
    }
    .badge-special { background: var(--sun); }
    .badge-admin { background: #dbeafe; color: #1d4ed8; }
    .badge-auto { background: #f1f5f9; color: #475569; }

    .editor-pane { padding: 18px; min-height: 600px; }
    .day-banner {
      display: flex;
      flex-wrap: wrap;
      justify-content: space-between;
      align-items: center;
      gap: 12px;
      padding-bottom: 14px;
      border-bottom: 2px dashed #cbd5e1;
      margin-bottom: 14px;
    }
    .meta-bar {
      display: grid;
      grid-template-columns: auto 1fr auto;
      gap: 10px;
      align-items: center;
      background: #fffbeb;
      border: 2px solid var(--border);
      border-radius: 12px;
      padding: 10px 12px;
      margin-bottom: 16px;
    }
    @media (max-width: 720px) {
      .meta-bar { grid-template-columns: 1fr; }
    }
    .tabs { display: flex; flex-wrap: wrap; gap: 8px; margin-bottom: 16px; }
    .tab-btn {
      padding: 8px 13px;
      border: 2px solid var(--border);
      border-radius: 10px;
      background: #fff;
      font-weight: 800;
      font-size: 13px;
      cursor: pointer;
    }
    .tab-btn.active { background: var(--sun); box-shadow: 2px 2px 0 var(--border); }

    .grid-board {
      display: inline-grid;
      gap: 3px;
      padding: 8px;
      background: #f8fafc;
      border: 2px solid var(--border);
      border-radius: 12px;
      user-select: none;
    }
    .cell-btn {
      width: 46px;
      height: 46px;
      border: 2px solid #334155;
      border-radius: 8px;
      background: #fff;
      font-weight: 900;
      font-size: 15px;
      cursor: pointer;
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      position: relative;
    }
    .zip-wrap {
      display: inline-grid;
      align-items: center;
      justify-items: center;
      padding: 10px;
      background: #f8fafc;
      border: 2px solid var(--border);
      border-radius: 12px;
      user-select: none;
    }
    .wall-h { width: 44px; height: 10px; cursor: pointer; border-radius: 4px; background: transparent; }
    .wall-h:hover { background: #fed7aa; }
    .wall-h.on { background: #dc2626; }
    .wall-v { width: 10px; height: 44px; cursor: pointer; border-radius: 4px; background: transparent; }
    .wall-v:hover { background: #fed7aa; }
    .wall-v.on { background: #dc2626; }

    .toast {
      position: fixed;
      right: 20px;
      bottom: 20px;
      padding: 12px 18px;
      border-radius: 12px;
      border: 2px solid var(--border);
      background: #0f172a;
      color: #fff;
      font-weight: 700;
      font-size: 13.5px;
      box-shadow: 3px 3px 0 var(--sun);
      z-index: 99;
      display: none;
    }
    .status-ok { color: var(--green); font-weight: 700; font-size: 13px; }
    .status-bad { color: var(--red); font-weight: 700; font-size: 13px; }
    .row-2 { display: grid; grid-template-columns: 1fr 1fr; gap: 12px; }
    @media (max-width: 720px) { .row-2 { grid-template-columns: 1fr; } }
    .palette { display: flex; flex-wrap: wrap; gap: 6px; margin-bottom: 10px; }
    .swatch {
      width: 28px;
      height: 28px;
      border-radius: 7px;
      border: 2px solid var(--border);
      cursor: pointer;
      display: inline-grid;
      place-items: center;
      font-size: 11px;
      font-weight: 900;
    }
    .swatch.selected { outline: 3px solid #0f172a; transform: scale(1.1); }
  </style>
</head>
<body>
<?php if (!$loggedIn): ?>
  <div class="login-wrap">
    <form class="sketch-box login-card" method="POST" action="/admin/">
      <input type="hidden" name="csrf_token" value="<?= htmlspecialchars($csrfToken, ENT_QUOTES, 'UTF-8') ?>">
      <h1>🧠 Zühtü Admin</h1>
      <p>365 Günlük Bulmaca Takvimi &amp; Özel Gün Yönetimi</p>
      <?php if ($loginError !== null): ?>
        <div class="alert-err"><?= htmlspecialchars($loginError, ENT_QUOTES, 'UTF-8') ?></div>
      <?php endif; ?>
      <div class="field">
        <label for="username">Kullanıcı Adı</label>
        <input id="username" name="username" type="text" autocomplete="username" required autofocus>
      </div>
      <div class="field">
        <label for="password">Şifre</label>
        <input id="password" name="password" type="password" autocomplete="current-password" required>
      </div>
      <button class="btn btn-sun" style="width:100%; justify-content:center; padding:11px;" type="submit">
        Giriş Yap
      </button>
    </form>
  </div>
<?php else: ?>
  <header class="topbar">
    <div class="brand">
      <span>🧠 Zühtü</span>
      <span class="tag">365 Gün Takvimi</span>
    </div>
    <div class="topbar-actions">
      <button class="btn btn-sun" id="btnGenerateYear" type="button">📅 365 Günü Tamamla</button>
      <a class="btn btn-blue" href="/" target="_blank">🎮 Oyunu Aç</a>
      <form method="POST" action="/admin/?action=logout" style="margin:0;">
        <input type="hidden" name="csrf_token" value="<?= htmlspecialchars($csrfToken, ENT_QUOTES, 'UTF-8') ?>">
        <button class="btn btn-red" type="submit">Çıkış</button>
      </form>
    </div>
  </header>

  <main class="layout">
    <aside class="sketch-box sidebar">
      <div class="row-2" style="gap:8px;">
        <div>
          <label for="searchDate">Tarih / Kelime Ara</label>
          <input id="searchDate" type="text" placeholder="2026-11 veya KAHVE...">
        </div>
        <div>
          <label for="monthFilter">Ay Seçimi</label>
          <select id="monthFilter">
            <option value="all">Tüm Aylar (365 Gün)</option>
          </select>
        </div>
      </div>
      <div class="filter-row">
        <button class="pill active" data-filter="all" type="button">Tümü</button>
        <button class="pill" data-filter="special" type="button">⭐ Özel Günler</button>
        <button class="pill" data-filter="admin" type="button">✏️ Düzenlenenler</button>
      </div>
      <div id="calendarCount" style="font-size:12px; color:var(--muted); font-weight:700;">Yükleniyor...</div>
      <div id="dayList" class="day-list"></div>
    </aside>

    <section class="sketch-box editor-pane" id="editorPane">
      <div id="editorLoading" style="padding:30px; text-align:center; color:var(--muted); font-weight:700;">
        Takvim yükleniyor...
      </div>
      <div id="editorContent" style="display:none;">
        <div class="day-banner">
          <div>
            <h2 id="selectedDateHeading" style="margin:0; font-size:22px;">-</h2>
            <div id="selectedDateSub" style="font-size:13px; color:var(--muted); margin-top:3px;"></div>
          </div>
          <div style="display:flex; gap:8px; flex-wrap:wrap;">
            <button class="btn btn-sm" id="btnRegenDay" type="button">🎲 Tüm Günü Otomatik Yenile</button>
          </div>
        </div>

        <div class="meta-bar">
          <label style="display:flex; align-items:center; gap:8px; margin:0; cursor:pointer; color:var(--ink); font-size:14px;">
            <input id="chkSpecial" type="checkbox" style="width:18px; height:18px;">
            <span>⭐ Özel Gün</span>
          </label>
          <input id="inpSpecialNote" type="text" placeholder="Özel gün notu (örn. 23 Nisan Özel Bölümü)">
          <button class="btn btn-sun btn-sm" id="btnSaveMeta" type="button">Notu Kaydet</button>
        </div>

        <div class="tabs" id="gameTabs">
          <button class="tab-btn active" data-game="pinpoint" type="button">🔍 Kelime İzleri</button>
          <button class="tab-btn" data-game="crossclimb" type="button">🪜 Kelime Tırmanışı</button>
          <button class="tab-btn" data-game="zip_path" type="button">〰️ Sayı Yolu</button>
          <button class="tab-btn" data-game="queens" type="button">👑 Vezirler</button>
          <button class="tab-btn" data-game="tango" type="button">☀️ Güneş &amp; Ay</button>
          <button class="tab-btn" data-game="patches" type="button">🧩 Alan Bölme</button>
        </div>

        <div id="gameEditorArea"></div>
      </div>
    </section>
  </main>

  <div class="toast" id="toast"></div>

  <script>
    window.ZUHTU_CSRF = <?= json_encode($csrfToken) ?>;
  </script>
  <script src="/admin/admin.js?v=1"></script>
<?php endif; ?>
</body>
</html>

