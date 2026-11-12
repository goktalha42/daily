(() => {
  const MONTHS_TR = [
    'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
    'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
  ];
  const DAYS_TR = ['Pazar', 'Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi'];
  const REGION_COLORS = [
    '#fde68a', '#bae6fd', '#fbcfe8', '#ddd6fe', '#fed7aa',
    '#bbf7d0', '#fca5a5', '#c7d2fe', '#99f6e4'
  ];

  let calendar = [];
  let activeFilter = 'all';
  let selectedDate = null;
  let dayData = null;
  let activeGame = 'pinpoint';
  let activeQueensDiff = 'kolay';

  const dayListEl = document.getElementById('dayList');
  const calendarCountEl = document.getElementById('calendarCount');
  const monthFilterEl = document.getElementById('monthFilter');
  const searchEl = document.getElementById('searchDate');
  const editorLoadingEl = document.getElementById('editorLoading');
  const editorContentEl = document.getElementById('editorContent');
  const gameEditorArea = document.getElementById('gameEditorArea');
  const toastEl = document.getElementById('toast');

  function showToast(msg, isErr = false) {
    toastEl.textContent = msg;
    toastEl.style.background = isErr ? '#991b1b' : '#0f172a';
    toastEl.style.display = 'block';
    clearTimeout(showToast._t);
    showToast._t = setTimeout(() => { toastEl.style.display = 'none'; }, 3500);
  }

  function escapeHtml(s) {
    return String(s ?? '')
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;');
  }

  function formatDateTr(dateId) {
    const [y, m, d] = dateId.split('-').map(Number);
    const dt = new Date(y, m - 1, d);
    return `${d} ${MONTHS_TR[m - 1]} ${y} ${DAYS_TR[dt.getDay()]}`;
  }

  function normTr(s) {
    return String(s ?? '').trim().toLocaleUpperCase('tr-TR');
  }

  async function apiFetch(endpoint, opts = {}) {
    const method = opts.method || 'GET';
    const params = new URLSearchParams(opts.query || {});
    params.set('endpoint', endpoint);
    const headers = { 'Accept': 'application/json' };
    if (method !== 'GET') {
      headers['Content-Type'] = 'application/json';
      headers['X-CSRF-Token'] = window.ZUHTU_CSRF;
    }
    const res = await fetch(`/admin/api.php?${params.toString()}`, {
      method,
      headers,
      body: opts.body ? JSON.stringify(opts.body) : undefined,
    });
    const data = await res.json().catch(() => ({}));
    if (res.status === 401) {
      window.location.reload();
      throw new Error('Oturum sona erdi');
    }
    if (!res.ok) {
      throw new Error(data.message || `Sunucu hatası (${res.status})`);
    }
    return data;
  }

  async function loadCalendar(keepSelection = true) {
    try {
      const now = new Date();
      const todayStr = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}-${String(now.getDate()).padStart(2, '0')}`;
      const res = await apiFetch('calendar', { query: { from: todayStr, days: 365 } });
      calendar = res.calendar || [];
      buildMonthOptions();
      renderCalendar();
      if (!keepSelection || !selectedDate) {
        if (calendar.length > 0) {
          selectDate(calendar[0].date_id);
        }
      }
    } catch (e) {
      showToast(e.message, true);
    }
  }

  function buildMonthOptions() {
    const months = new Set(calendar.map(d => d.date_id.slice(0, 7)));
    const prev = monthFilterEl.value;
    monthFilterEl.innerHTML = '<option value="all">Tüm Aylar (365 Gün)</option>';
    for (const ym of months) {
      const [y, m] = ym.split('-').map(Number);
      const opt = document.createElement('option');
      opt.value = ym;
      opt.textContent = `${MONTHS_TR[m - 1]} ${y}`;
      monthFilterEl.appendChild(opt);
    }
    if ([...months].includes(prev)) monthFilterEl.value = prev;
  }

  function renderCalendar() {
    const q = normTr(searchEl.value);
    const monthVal = monthFilterEl.value;
    const filtered = calendar.filter(item => {
      if (activeFilter === 'special' && !item.is_special) return false;
      if (activeFilter === 'admin' && (item.admin_count || 0) === 0) return false;
      if (monthVal !== 'all' && !item.date_id.startsWith(monthVal)) return false;
      if (q) {
        const hay = `${item.date_id} ${item.special_note || ''} ${item.summary?.pinpoint || ''} ${item.summary?.crossclimb || ''}`.toLocaleUpperCase('tr-TR');
        if (!hay.includes(q)) return false;
      }
      return true;
    });

    calendarCountEl.textContent = `${filtered.length} / ${calendar.length} gün listeleniyor`;
    dayListEl.innerHTML = '';

    for (const item of filtered) {
      const div = document.createElement('div');
      div.className = 'day-item' + (item.date_id === selectedDate ? ' active' : '') + (item.is_special ? ' special' : '');
      const badgeHtml = item.is_special
        ? `<span class="badge badge-special">⭐ ${escapeHtml(item.special_note || 'Özel Gün')}</span>`
        : (item.admin_count > 0
          ? `<span class="badge badge-admin">✏️ ${item.admin_count} özel</span>`
          : `<span class="badge badge-auto">Oto</span>`);

      div.innerHTML = `
        <div class="day-head">
          <span>${escapeHtml(formatDateTr(item.date_id))}</span>
          ${badgeHtml}
        </div>
        <div class="day-sub">
          <span><b>${escapeHtml(item.date_id)}</b></span>
          <span>🔍 ${escapeHtml(item.summary?.pinpoint || '-')}</span>
          <span>🪜 ${escapeHtml(item.summary?.crossclimb || '-')}</span>
        </div>
      `;
      div.onclick = () => selectDate(item.date_id);
      dayListEl.appendChild(div);
    }
  }

  async function selectDate(dateId) {
    selectedDate = dateId;
    renderCalendar();
    editorContentEl.style.display = 'none';
    editorLoadingEl.style.display = 'block';
    editorLoadingEl.textContent = `${dateId} yükleniyor...`;

    try {
      dayData = await apiFetch(`day/${dateId}`);
      editorLoadingEl.style.display = 'none';
      editorContentEl.style.display = 'block';

      document.getElementById('selectedDateHeading').textContent = formatDateTr(dateId);
      document.getElementById('selectedDateSub').textContent = `Tarih Kodu: ${dateId}`;
      document.getElementById('chkSpecial').checked = !!dayData.is_special;
      document.getElementById('inpSpecialNote').value = dayData.special_note || '';
      renderActiveGameEditor();
    } catch (e) {
      editorLoadingEl.textContent = `Hata: ${e.message}`;
      showToast(e.message, true);
    }
  }

  function findEntry(gameType, difficulty = 'default') {
    return (dayData?.entries || []).find(
      e => e.game_type === gameType && e.difficulty === difficulty
    );
  }

  async function saveGameEntry(gameType, difficulty, payload) {
    try {
      const body = {
        difficulty,
        payload,
        is_special: document.getElementById('chkSpecial').checked,
        special_note: document.getElementById('inpSpecialNote').value.trim() || null,
      };
      const res = await apiFetch(`day/${selectedDate}/${gameType}`, {
        method: 'PUT',
        body,
      });
      const entry = findEntry(gameType, difficulty);
      if (entry) {
        entry.payload = res.payload;
        entry.source = 'admin';
      }
      showToast('Kaydedildi! Artık tüm telefonlarda ve sitede aktif.');
      await loadCalendar(true);
      renderActiveGameEditor();
    } catch (e) {
      showToast(e.message, true);
    }
  }

  async function regenerateGameEntry(gameType, difficulty = 'default') {
    try {
      const res = await apiFetch(`day/${selectedDate}/regenerate`, {
        method: 'POST',
        body: { game_type: gameType, difficulty },
      });
      if (gameType === 'all') {
        await selectDate(selectedDate);
        await loadCalendar(true);
        showToast('Günün tüm oyunları yeniden üretildi.');
        return;
      }
      const entry = findEntry(gameType, difficulty);
      if (entry) {
        entry.payload = res.payload;
        entry.source = res.source;
      }
      await loadCalendar(true);
      renderActiveGameEditor();
      showToast('Yeni rastgele bulmaca üretildi.');
    } catch (e) {
      showToast(e.message, true);
    }
  }

  function sourceBadgeHtml(entry) {
    if (!entry) return '';
    return entry.source === 'admin'
      ? '<span class="badge badge-admin">✏️ Admin Özelleştirmesi</span>'
      : '<span class="badge badge-auto">🤖 Otomatik Üretim</span>';
  }

  function renderJsonPanel(container, payload, onApplyJson) {
    const details = document.createElement('details');
    details.style.marginTop = '16px';
    details.innerHTML = `
      <summary style="cursor:pointer; font-weight:700; font-size:13px; color:var(--muted);">Gelişmiş JSON Görünümü</summary>
      <div style="margin-top:8px;">
        <textarea rows="8" style="font-family:monospace; font-size:12px;">${escapeHtml(JSON.stringify(payload, null, 2))}</textarea>
        <div style="margin-top:6px;">
          <button type="button" class="btn btn-sm">JSON'dan Uygula</button>
        </div>
      </div>
    `;
    const ta = details.querySelector('textarea');
    details.querySelector('button').onclick = () => {
      try {
        const parsed = JSON.parse(ta.value);
        onApplyJson(parsed);
      } catch (e) {
        showToast('Geçersiz JSON: ' + e.message, true);
      }
    };
    container.appendChild(details);
  }

  function renderActiveGameEditor() {
    if (!dayData) return;
    gameEditorArea.innerHTML = '';

    if (activeGame === 'pinpoint') renderPinpointEditor();
    else if (activeGame === 'crossclimb') renderCrossclimbEditor();
    else if (activeGame === 'zip_path') renderZipEditor();
    else if (activeGame === 'queens') renderQueensEditor();
    else if (activeGame === 'tango') renderTangoEditor();
    else if (activeGame === 'patches') renderPatchesEditor();
  }

  // ---------------------------------------------------------------------------
  // 1. PINPOINT (Kelime İzleri)
  // ---------------------------------------------------------------------------
  function renderPinpointEditor() {
    const entry = findEntry('pinpoint', 'default');
    const p = JSON.parse(JSON.stringify(entry?.payload || { categoryHint: '', targetWord: '', clues: ['', '', '', '', ''], alternativeAnswers: [] }));
    while ((p.clues || []).length < 5) p.clues.push('');

    const wrap = document.createElement('div');
    wrap.innerHTML = `
      <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:12px;">
        <div><b>Kelime İzleri</b> ${sourceBadgeHtml(entry)}</div>
        <button class="btn btn-sm" id="ppRegen" type="button">🎲 Rastgele Üret</button>
      </div>
      <div class="row-2" style="margin-bottom:12px;">
        <div>
          <label>Kategori İpucu</label>
          <input id="ppCat" type="text" value="${escapeHtml(p.categoryHint)}">
        </div>
        <div>
          <label>Hedef Kelime (Cevap)</label>
          <input id="ppTarget" type="text" value="${escapeHtml(p.targetWord)}">
        </div>
      </div>
      <div style="margin-bottom:12px;">
        <label>5 Aşamalı İpucu Kelimeleri</label>
        <div style="display:grid; gap:8px;">
          ${[0, 1, 2, 3, 4].map(i => `<input class="ppClue" data-idx="${i}" type="text" placeholder="${i + 1}. ipucu" value="${escapeHtml(p.clues[i] || '')}">`).join('')}
        </div>
      </div>
      <div style="margin-bottom:14px;">
        <label>Alternatif Kabul Edilen Cevaplar (virgülle ayırın)</label>
        <input id="ppAlt" type="text" value="${escapeHtml((p.alternativeAnswers || []).join(', '))}">
      </div>
      <button class="btn btn-sun" id="ppSave" type="button">💾 Özel Bölüm Olarak Kaydet</button>
    `;
    gameEditorArea.appendChild(wrap);

    wrap.querySelector('#ppRegen').onclick = () => regenerateGameEntry('pinpoint', 'default');
    wrap.querySelector('#ppSave').onclick = () => {
      const payload = {
        id: selectedDate,
        categoryHint: wrap.querySelector('#ppCat').value.trim(),
        targetWord: normTr(wrap.querySelector('#ppTarget').value),
        clues: [...wrap.querySelectorAll('.ppClue')].map(el => el.value.trim()).filter(Boolean),
        alternativeAnswers: wrap.querySelector('#ppAlt').value.split(',').map(normTr).filter(Boolean),
      };
      saveGameEntry('pinpoint', 'default', payload);
    };
    renderJsonPanel(wrap, p, (parsed) => saveGameEntry('pinpoint', 'default', parsed));
  }

  // ---------------------------------------------------------------------------
  // 2. CROSSCLIMB (Kelime Tırmanışı)
  // ---------------------------------------------------------------------------
  function countDiff(a, b) {
    if (!a || !b || a.length !== b.length) return -1;
    let d = 0, lastIdx = 0;
    for (let i = 0; i < a.length; i++) {
      if (a[i] !== b[i]) { d++; lastIdx = i; }
    }
    return d === 1 ? lastIdx : -1;
  }

  function renderCrossclimbEditor() {
    const entry = findEntry('crossclimb', 'default');
    const p = JSON.parse(JSON.stringify(entry?.payload || { startWord: 'KARA', endWord: 'SIRA', steps: [] }));

    const wrap = document.createElement('div');
    const draw = () => {
      wrap.innerHTML = `
        <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:12px;">
          <div><b>Kelime Tırmanışı</b> ${sourceBadgeHtml(entry)}</div>
          <div style="display:flex; gap:8px;">
            <button class="btn btn-sm" id="ccAddStep" type="button">+ Adım Ekle</button>
            <button class="btn btn-sm" id="ccRegen" type="button">🎲 Rastgele Üret</button>
          </div>
        </div>
        <div class="row-2" style="margin-bottom:12px;">
          <div>
            <label>Başlangıç Kelimesi (Açık verilir)</label>
            <input id="ccStart" type="text" value="${escapeHtml(p.startWord)}">
          </div>
          <div>
            <label>Bitiş Kelimesi (Son adımla aynı olmalı)</label>
            <input id="ccEnd" type="text" value="${escapeHtml(p.endWord)}">
          </div>
        </div>
        <div id="ccStepsBox" style="display:grid; gap:10px; margin-bottom:12px;"></div>
        <div id="ccValidation" style="margin-bottom:12px;"></div>
        <button class="btn btn-sun" id="ccSave" type="button">💾 Özel Zinciri Kaydet</button>
      `;

      const stepsBox = wrap.querySelector('#ccStepsBox');
      let prev = normTr(p.startWord);
      let allOk = true;
      const errMsgs = [];

      (p.steps || []).forEach((st, idx) => {
        const cur = normTr(st.targetWord);
        const ch = countDiff(prev, cur);
        if (ch < 0) {
          allOk = false;
          errMsgs.push(`${idx + 1}. adım: '${prev}' → '${cur}' tam 1 harf farklı değil!`);
        }
        st.changedIndex = ch >= 0 ? ch : 0;
        st.index = idx;

        const row = document.createElement('div');
        row.style.cssText = 'display:grid; grid-template-columns: 140px 1fr auto; gap:8px; align-items:center; padding:8px; border:1.5px solid #cbd5e1; border-radius:10px; background:#f8fafc;';
        row.innerHTML = `
          <div>
            <label>${idx + 1}. Kelime (${ch >= 0 ? '✅ 1 harf' : '❌ Hatalı'})</label>
            <input type="text" class="ccWord" value="${escapeHtml(cur)}">
          </div>
          <div>
            <label>İpucu</label>
            <input type="text" class="ccClue" value="${escapeHtml(st.clue || '')}">
          </div>
          <button type="button" class="btn btn-red btn-sm" style="margin-top:16px;">Sil</button>
        `;
        row.querySelector('.ccWord').oninput = (e) => {
          st.targetWord = normTr(e.target.value);
          if (idx === p.steps.length - 1) p.endWord = st.targetWord;
          validateAndBadge();
        };
        row.querySelector('.ccClue').oninput = (e) => { st.clue = e.target.value; };
        row.querySelector('button').onclick = () => {
          p.steps.splice(idx, 1);
          draw();
        };
        stepsBox.appendChild(row);
        prev = cur;
      });

      if (prev !== normTr(p.endWord)) {
        allOk = false;
        errMsgs.push(`Son adım ('${prev}') ile bitiş kelimesi ('${normTr(p.endWord)}') aynı olmalı.`);
      }

      function validateAndBadge() {
        const valEl = wrap.querySelector('#ccValidation');
        let pr = normTr(wrap.querySelector('#ccStart').value);
        const endW = normTr(wrap.querySelector('#ccEnd').value);
        const errs = [];
        p.startWord = pr;
        p.endWord = endW;
        (p.steps || []).forEach((s, i) => {
          const w = normTr(s.targetWord);
          const ch = countDiff(pr, w);
          if (ch < 0) errs.push(`${i + 1}. adım: '${pr}' → '${w}' geçersiz`);
          s.changedIndex = ch >= 0 ? ch : 0;
          s.index = i;
          pr = w;
        });
        if (pr !== endW) errs.push(`Son adım '${pr}' ≠ Bitiş '${endW}'`);
        valEl.innerHTML = errs.length === 0
          ? '<span class="status-ok">✅ Tüm harf geçişleri geçerli!</span>'
          : `<span class="status-bad">❌ ${escapeHtml(errs.join(' | '))}</span>`;
      }

      wrap.querySelector('#ccStart').oninput = validateAndBadge;
      wrap.querySelector('#ccEnd').oninput = validateAndBadge;
      validateAndBadge();

      wrap.querySelector('#ccAddStep').onclick = () => {
        p.steps.push({ targetWord: '', clue: '', index: p.steps.length, changedIndex: 0 });
        draw();
      };
      wrap.querySelector('#ccRegen').onclick = () => regenerateGameEntry('crossclimb', 'default');
      wrap.querySelector('#ccSave').onclick = () => {
        p.id = selectedDate;
        p.startWord = normTr(wrap.querySelector('#ccStart').value);
        p.endWord = normTr(wrap.querySelector('#ccEnd').value);
        p.steps = p.steps.map((s, i) => ({
          targetWord: normTr(s.targetWord),
          clue: (s.clue || '').trim(),
          index: i,
          changedIndex: s.changedIndex || 0,
        }));
        saveGameEntry('crossclimb', 'default', p);
      };
      renderJsonPanel(wrap, p, (parsed) => saveGameEntry('crossclimb', 'default', parsed));
    };

    gameEditorArea.appendChild(wrap);
    draw();
  }

  // ---------------------------------------------------------------------------
  // 3. ZIP PATH (Sayı Yolu - Görsel Çizim Editörü)
  // ---------------------------------------------------------------------------
  function renderZipEditor() {
    const entry = findEntry('zip_path', 'default');
    const p = JSON.parse(JSON.stringify(entry?.payload || { gridSize: 5, difficulty: 'orta', numberPoints: [], walls: [], edgeWalls: [], solutionPath: [] }));

    let mode = 'path'; // path | checkpoint | wall
    let path = (p.solutionPath || []).map(pt => ({ row: pt.row, col: pt.col }));
    let checkpoints = new Set((p.numberPoints || []).map(pt => `${pt.row},${pt.col}`));
    let edgeWalls = (p.edgeWalls || []).slice();

    const wrap = document.createElement('div');
    gameEditorArea.innerHTML = '';
    gameEditorArea.appendChild(wrap);

    function hasEdgeWall(r1, c1, r2, c2) {
      return edgeWalls.some(w =>
        (w.r1 === r1 && w.c1 === c1 && w.r2 === r2 && w.c2 === c2) ||
        (w.r1 === r2 && w.c1 === c2 && w.r2 === r1 && w.c2 === c1)
      );
    }

    function toggleEdgeWall(r1, c1, r2, c2) {
      const idx = edgeWalls.findIndex(w =>
        (w.r1 === r1 && w.c1 === c1 && w.r2 === r2 && w.c2 === c2) ||
        (w.r1 === r2 && w.c1 === c2 && w.r2 === r1 && w.c2 === c1)
      );
      if (idx >= 0) edgeWalls.splice(idx, 1);
      else edgeWalls.push({ r1, c1, r2, c2 });
      draw();
    }

    function pathContainsEdge(r1, c1, r2, c2) {
      for (let i = 0; i < path.length - 1; i++) {
        const a = path[i], b = path[i + 1];
        if ((a.row === r1 && a.col === c1 && b.row === r2 && b.col === c2) ||
            (a.row === r2 && a.col === c2 && b.row === r1 && b.col === c1)) return true;
      }
      return false;
    }

    function computeNumberPoints() {
      const pts = [];
      let num = 1;
      for (let i = 0; i < path.length; i++) {
        const k = `${path[i].row},${path[i].col}`;
        if (i === 0 || i === path.length - 1 || checkpoints.has(k)) {
          pts.push({ row: path[i].row, col: path[i].col, num: num++ });
        }
      }
      return pts;
    }

    function draw() {
      const n = Number(p.gridSize) || 5;
      const numPts = computeNumberPoints();
      const numMap = new Map(numPts.map(x => [`${x.row},${x.col}`, x.num]));
      const pathIdxMap = new Map(path.map((pt, idx) => [`${pt.row},${pt.col}`, idx]));

      wrap.innerHTML = `
        <div style="display:flex; justify-content:space-between; align-items:center; flex-wrap:wrap; gap:8px; margin-bottom:12px;">
          <div><b>Sayı Yolu Görsel Çizici</b> ${sourceBadgeHtml(entry)}</div>
          <div style="display:flex; gap:8px; align-items:center;">
            <select id="zipSize" style="width:auto;">
              <option value="4" ${n === 4 ? 'selected' : ''}>4×4 (Kolay)</option>
              <option value="5" ${n === 5 ? 'selected' : ''}>5×5 (Orta/Zor)</option>
              <option value="6" ${n === 6 ? 'selected' : ''}>6×6 (Büyük)</option>
            </select>
            <button class="btn btn-sm" id="zipClear" type="button">🧹 Tahtayı Temizle</button>
            <button class="btn btn-sm" id="zipRegen" type="button">🎲 Rastgele Üret</button>
          </div>
        </div>
        <div style="display:flex; flex-wrap:wrap; gap:8px; margin-bottom:12px;">
          <button type="button" class="pill ${mode === 'path' ? 'active' : ''}" data-m="path">🖊️ Sayı Yolu Çiz (1→N)</button>
          <button type="button" class="pill ${mode === 'checkpoint' ? 'active' : ''}" data-m="checkpoint">🔢 Kontrol Noktası İşaretle</button>
          <button type="button" class="pill ${mode === 'wall' ? 'active' : ''}" data-m="wall">🧱 Kareler Arası Duvar</button>
        </div>
        <div id="zipBoardHost"></div>
        <div style="margin:10px 0;">
          ${path.length === n * n
            ? `<span class="status-ok">✅ Rota tüm tahtayı kaplıyor (${path.length}/${n * n}), ${numPts.length} numaralı nokta hazır!</span>`
            : `<span class="status-bad">⚠️ Çizilen rota ${path.length}/${n * n} hücre kaplıyor. Komşu hücrelere tıklayarak tamamlayın (son hücreye tekrar tıklayarak geri alabilirsiniz).</span>`}
        </div>
        <button class="btn btn-sun" id="zipSave" type="button">💾 Özel Sayı Yolunu Kaydet</button>
      `;

      wrap.querySelectorAll('[data-m]').forEach(btn => {
        btn.onclick = () => { mode = btn.dataset.m; draw(); };
      });
      wrap.querySelector('#zipSize').onchange = (e) => {
        p.gridSize = Number(e.target.value);
        path = [];
        checkpoints.clear();
        edgeWalls = [];
        draw();
      };
      wrap.querySelector('#zipClear').onclick = () => {
        path = [];
        checkpoints.clear();
        edgeWalls = [];
        draw();
      };
      wrap.querySelector('#zipRegen').onclick = () => regenerateGameEntry('zip_path', 'default');

      const board = document.createElement('div');
      board.className = 'zip-wrap';
      board.style.gridTemplateColumns = Array.from({ length: n * 2 - 1 }, (_, i) => i % 2 === 0 ? '44px' : '12px').join(' ');

      for (let gr = 0; gr < n * 2 - 1; gr++) {
        for (let gc = 0; gc < n * 2 - 1; gc++) {
          if (gr % 2 === 0 && gc % 2 === 0) {
            const r = gr / 2, c = gc / 2;
            const k = `${r},${c}`;
            const pIdx = pathIdxMap.get(k);
            const cpNum = numMap.get(k);
            const cell = document.createElement('button');
            cell.type = 'button';
            cell.className = 'cell-btn';
            cell.style.width = '44px';
            cell.style.height = '44px';
            cell.style.background = cpNum ? '#facc15' : (pIdx !== undefined ? '#bae6fd' : '#fff');
            cell.innerHTML = cpNum
              ? `<span style="font-size:15px;">${cpNum}</span><span style="font-size:9px; color:#475569;">#${pIdx + 1}</span>`
              : (pIdx !== undefined ? `<span style="font-size:11px; color:#0369a1;">#${pIdx + 1}</span>` : '');

            cell.onclick = () => {
              if (mode === 'path') {
                if (path.length === 0) {
                  path.push({ row: r, col: c });
                  checkpoints.add(k);
                } else {
                  const last = path[path.length - 1];
                  if (last.row === r && last.col === c) {
                    path.pop();
                  } else if (Math.abs(last.row - r) + Math.abs(last.col - c) === 1 && !pathIdxMap.has(k) && !hasEdgeWall(last.row, last.col, r, c)) {
                    path.push({ row: r, col: c });
                  } else if (pathIdxMap.has(k)) {
                    const cut = pathIdxMap.get(k);
                    path = path.slice(0, cut + 1);
                  } else {
                    showToast('Sadece komşu (duvarsız) ve geçilmemiş hücreye gidebilirsiniz.', true);
                    return;
                  }
                }
                draw();
              } else if (mode === 'checkpoint') {
                if (pIdx === undefined) return;
                if (checkpoints.has(k)) checkpoints.delete(k);
                else checkpoints.add(k);
                draw();
              }
            };
            board.appendChild(cell);
          } else if (gr % 2 === 0 && gc % 2 === 1) {
            const r = gr / 2, c1 = (gc - 1) / 2, c2 = c1 + 1;
            const d = document.createElement('div');
            d.className = 'wall-v' + (hasEdgeWall(r, c1, r, c2) ? ' on' : '');
            d.title = 'Dikey duvar koy/kaldır';
            d.onclick = () => {
              if (pathContainsEdge(r, c1, r, c2)) {
                showToast('Çizili rotanın geçtiği kenara duvar konulamaz.', true);
                return;
              }
              toggleEdgeWall(r, c1, r, c2);
            };
            board.appendChild(d);
          } else if (gr % 2 === 1 && gc % 2 === 0) {
            const r1 = (gr - 1) / 2, r2 = r1 + 1, c = gc / 2;
            const d = document.createElement('div');
            d.className = 'wall-h' + (hasEdgeWall(r1, c, r2, c) ? ' on' : '');
            d.title = 'Yatay duvar koy/kaldır';
            d.onclick = () => {
              if (pathContainsEdge(r1, c, r2, c)) {
                showToast('Çizili rotanın geçtiği kenara duvar konulamaz.', true);
                return;
              }
              toggleEdgeWall(r1, c, r2, c);
            };
            board.appendChild(d);
          } else {
            const spacer = document.createElement('div');
            board.appendChild(spacer);
          }
        }
      }
      wrap.querySelector('#zipBoardHost').appendChild(board);

      wrap.querySelector('#zipSave').onclick = () => {
        if (path.length !== n * n) {
          showToast(`Önce tüm ${n * n} hücreyi kapsayan Sayı Yolu rotasını tamamlayın.`, true);
          return;
        }
        const payload = {
          id: selectedDate,
          gridSize: n,
          difficulty: n <= 4 ? 'kolay' : (n === 5 ? 'orta' : 'zor'),
          numberPoints: numPts,
          walls: [],
          edgeWalls,
          solutionPath: path,
        };
        saveGameEntry('zip_path', 'default', payload);
      };
      renderJsonPanel(wrap, {
        id: selectedDate, gridSize: n, numberPoints: numPts, edgeWalls, solutionPath: path,
      }, (parsed) => saveGameEntry('zip_path', 'default', parsed));
    }

    draw();
  }

  // ---------------------------------------------------------------------------
  // 4. QUEENS (Vezirler - Kolay/Zor/Master)
  // ---------------------------------------------------------------------------
  function renderQueensEditor() {
    const entry = findEntry('queens', activeQueensDiff);
    const p = JSON.parse(JSON.stringify(entry?.payload || { gridSize: 6, difficulty: activeQueensDiff, queensPerUnit: 1, regionMap: [], solution: [] }));
    let selectedRegion = 0;
    let paintMode = 'region'; // region | queen

    const wrap = document.createElement('div');
    gameEditorArea.innerHTML = '';
    gameEditorArea.appendChild(wrap);

    function draw() {
      const n = p.gridSize || p.regionMap.length;
      const qpu = p.queensPerUnit || (activeQueensDiff === 'master' ? 2 : 1);
      const queenSet = new Set((p.solution || []).map(([r, c]) => `${r},${c}`));

      wrap.innerHTML = `
        <div style="display:flex; justify-content:space-between; align-items:center; flex-wrap:wrap; gap:8px; margin-bottom:10px;">
          <div><b>Vezirler (${activeQueensDiff.toUpperCase()})</b> ${sourceBadgeHtml(entry)}</div>
          <div style="display:flex; gap:6px;">
            ${['kolay', 'zor', 'master'].map(df => `<button type="button" class="pill ${activeQueensDiff === df ? 'active' : ''}" data-qd="${df}">${df.toUpperCase()}</button>`).join('')}
            <button class="btn btn-sm" id="qRegen" type="button">🎲 Rastgele Üret</button>
          </div>
        </div>
        <div style="display:flex; gap:8px; flex-wrap:wrap; margin-bottom:10px;">
          <button type="button" class="pill ${paintMode === 'region' ? 'active' : ''}" data-qm="region">🎨 Renk Bölgesi Boya</button>
          <button type="button" class="pill ${paintMode === 'queen' ? 'active' : ''}" data-qm="queen">👑 Vezir Yerleştir</button>
        </div>
        <div class="palette" id="qPalette"></div>
        <div id="qBoard"></div>
        <div style="margin:10px 0; font-size:13px; font-weight:700;">Vezir Sayısı: ${queenSet.size} / ${n * qpu}</div>
        <button class="btn btn-sun" id="qSave" type="button">💾 Vezirler (${activeQueensDiff.toUpperCase()}) Kaydet</button>
      `;

      wrap.querySelectorAll('[data-qd]').forEach(b => {
        b.onclick = () => { activeQueensDiff = b.dataset.qd; renderActiveGameEditor(); };
      });
      wrap.querySelectorAll('[data-qm]').forEach(b => {
        b.onclick = () => { paintMode = b.dataset.qm; draw(); };
      });
      wrap.querySelector('#qRegen').onclick = () => regenerateGameEntry('queens', activeQueensDiff);

      const pal = wrap.querySelector('#qPalette');
      for (let i = 0; i < n; i++) {
        const sw = document.createElement('button');
        sw.type = 'button';
        sw.className = 'swatch' + (selectedRegion === i && paintMode === 'region' ? ' selected' : '');
        sw.style.background = REGION_COLORS[i % REGION_COLORS.length];
        sw.textContent = i + 1;
        sw.onclick = () => { paintMode = 'region'; selectedRegion = i; draw(); };
        pal.appendChild(sw);
      }

      const board = document.createElement('div');
      board.className = 'grid-board';
      board.style.gridTemplateColumns = `repeat(${n}, 40px)`;
      for (let r = 0; r < n; r++) {
        for (let c = 0; c < n; c++) {
          const rid = p.regionMap[r][c];
          const hasQ = queenSet.has(`${r},${c}`);
          const btn = document.createElement('button');
          btn.type = 'button';
          btn.className = 'cell-btn';
          btn.style.width = '40px';
          btn.style.height = '40px';
          btn.style.background = REGION_COLORS[rid % REGION_COLORS.length];
          btn.textContent = hasQ ? '👑' : '';
          btn.onclick = () => {
            if (paintMode === 'region') {
              p.regionMap[r][c] = selectedRegion;
            } else {
              const idx = p.solution.findIndex(([qr, qc]) => qr === r && qc === c);
              if (idx >= 0) p.solution.splice(idx, 1);
              else p.solution.push([r, c]);
            }
            draw();
          };
          board.appendChild(btn);
        }
      }
      wrap.querySelector('#qBoard').appendChild(board);
      wrap.querySelector('#qSave').onclick = () => {
        p.id = selectedDate;
        saveGameEntry('queens', activeQueensDiff, p);
      };
      renderJsonPanel(wrap, p, (parsed) => saveGameEntry('queens', activeQueensDiff, parsed));
    }

    draw();
  }

  // ---------------------------------------------------------------------------
  // 5. TANGO (Güneş & Ay 6x6)
  // ---------------------------------------------------------------------------
  function renderTangoEditor() {
    const entry = findEntry('tango', 'default');
    const p = JSON.parse(JSON.stringify(entry?.payload || {
      gridSize: 6, difficulty: 'orta',
      initialGrid: Array.from({ length: 6 }, () => Array(6).fill(0)),
      constraints: [],
      solution: Array.from({ length: 6 }, () => Array(6).fill(1)),
    }));
    let targetLayer = 'initial'; // initial | solution

    const wrap = document.createElement('div');
    gameEditorArea.innerHTML = '';
    gameEditorArea.appendChild(wrap);

    function symChar(v) { return v === 1 ? '☀️' : (v === 2 ? '🌙' : ''); }

    function findConstraint(r1, c1, r2, c2) {
      return p.constraints.findIndex(k =>
        (k.r1 === r1 && k.c1 === c1 && k.r2 === r2 && k.c2 === c2) ||
        (k.r1 === r2 && k.c1 === c2 && k.r2 === r1 && k.c2 === c1)
      );
    }

    function cycleConstraint(r1, c1, r2, c2) {
      const idx = findConstraint(r1, c1, r2, c2);
      if (idx < 0) p.constraints.push({ r1, c1, r2, c2, type: 'equal' });
      else if (p.constraints[idx].type === 'equal') p.constraints[idx].type = 'opposite';
      else p.constraints.splice(idx, 1);
      draw();
    }

    function draw() {
      const grid = targetLayer === 'initial' ? p.initialGrid : (p.solution || p.initialGrid);
      wrap.innerHTML = `
        <div style="display:flex; justify-content:space-between; align-items:center; flex-wrap:wrap; gap:8px; margin-bottom:10px;">
          <div><b>Güneş &amp; Ay (6×6)</b> ${sourceBadgeHtml(entry)}</div>
          <button class="btn btn-sm" id="tRegen" type="button">🎲 Rastgele Üret</button>
        </div>
        <div style="display:flex; gap:8px; flex-wrap:wrap; margin-bottom:12px;">
          <button type="button" class="pill ${targetLayer === 'initial' ? 'active' : ''}" data-tl="initial">🔒 Başlangıç İpuçları</button>
          <button type="button" class="pill ${targetLayer === 'solution' ? 'active' : ''}" data-tl="solution">✅ Çözüm Tahtası</button>
          <span style="font-size:12px; color:var(--muted); align-self:center;">(Kenar boşluklarına tıklayarak = veya × ekleyebilirsiniz)</span>
        </div>
        <div id="tBoard"></div>
        <div style="margin-top:12px;">
          <button class="btn btn-sun" id="tSave" type="button">💾 Güneş &amp; Ay Kaydet</button>
        </div>
      `;

      wrap.querySelectorAll('[data-tl]').forEach(b => {
        b.onclick = () => { targetLayer = b.dataset.tl; draw(); };
      });
      wrap.querySelector('#tRegen').onclick = () => regenerateGameEntry('tango', 'default');

      const board = document.createElement('div');
      board.className = 'zip-wrap';
      board.style.gridTemplateColumns = Array.from({ length: 11 }, (_, i) => i % 2 === 0 ? '42px' : '18px').join(' ');

      for (let gr = 0; gr < 11; gr++) {
        for (let gc = 0; gc < 11; gc++) {
          if (gr % 2 === 0 && gc % 2 === 0) {
            const r = gr / 2, c = gc / 2;
            const val = grid[r][c] || 0;
            const btn = document.createElement('button');
            btn.type = 'button';
            btn.className = 'cell-btn';
            btn.style.width = '42px';
            btn.style.height = '42px';
            btn.textContent = symChar(val);
            btn.onclick = () => {
              if (targetLayer === 'initial') grid[r][c] = (val + 1) % 3;
              else grid[r][c] = val === 1 ? 2 : 1;
              draw();
            };
            board.appendChild(btn);
          } else if (gr % 2 === 0 && gc % 2 === 1) {
            const r = gr / 2, c1 = (gc - 1) / 2, c2 = c1 + 1;
            const idx = findConstraint(r, c1, r, c2);
            const btn = document.createElement('button');
            btn.type = 'button';
            btn.style.cssText = 'width:18px; height:24px; border:1px dashed #cbd5e1; background:#fff; border-radius:4px; font-weight:900; font-size:11px; cursor:pointer; padding:0;';
            btn.textContent = idx < 0 ? '' : (p.constraints[idx].type === 'equal' ? '=' : '×');
            btn.onclick = () => cycleConstraint(r, c1, r, c2);
            board.appendChild(btn);
          } else if (gr % 2 === 1 && gc % 2 === 0) {
            const r1 = (gr - 1) / 2, r2 = r1 + 1, c = gc / 2;
            const idx = findConstraint(r1, c, r2, c);
            const btn = document.createElement('button');
            btn.type = 'button';
            btn.style.cssText = 'width:24px; height:18px; border:1px dashed #cbd5e1; background:#fff; border-radius:4px; font-weight:900; font-size:11px; cursor:pointer; padding:0;';
            btn.textContent = idx < 0 ? '' : (p.constraints[idx].type === 'equal' ? '=' : '×');
            btn.onclick = () => cycleConstraint(r1, c, r2, c);
            board.appendChild(btn);
          } else {
            board.appendChild(document.createElement('div'));
          }
        }
      }

      wrap.querySelector('#tBoard').appendChild(board);
      wrap.querySelector('#tSave').onclick = () => {
        p.id = selectedDate;
        saveGameEntry('tango', 'default', p);
      };
      renderJsonPanel(wrap, p, (parsed) => saveGameEntry('tango', 'default', parsed));
    }

    draw();
  }

  // ---------------------------------------------------------------------------
  // 6. PATCHES (Alan Bölme)
  // ---------------------------------------------------------------------------
  function renderPatchesEditor() {
    const entry = findEntry('patches', 'default');
    const p = JSON.parse(JSON.stringify(entry?.payload || { gridSize: 6, difficulty: 'orta', clues: [], solution: [] }));
    const wrap = document.createElement('div');
    gameEditorArea.innerHTML = '';
    gameEditorArea.appendChild(wrap);

    function draw() {
      const n = p.gridSize || 6;
      const clueMap = new Map((p.clues || []).map(c => [`${c.row},${c.col}`, c]));
      const rectColorMap = new Map();
      (p.solution || []).forEach((rect, idx) => {
        for (let r = rect.topRow; r <= rect.bottomRow; r++) {
          for (let c = rect.leftCol; c <= rect.rightCol; c++) {
            rectColorMap.set(`${r},${c}`, REGION_COLORS[(rect.colorIndex ?? idx) % REGION_COLORS.length]);
          }
        }
      });

      wrap.innerHTML = `
        <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:12px;">
          <div><b>Alan Bölme (${n}×${n})</b> ${sourceBadgeHtml(entry)}</div>
          <button class="btn btn-sm" id="paRegen" type="button">🎲 Rastgele Üret</button>
        </div>
        <div id="paBoard" style="margin-bottom:12px;"></div>
        <div style="font-size:12px; color:var(--muted); margin-bottom:10px;">Bir hücreye tıklayarak ipucu sayısını ve şeklini düzenleyebilirsiniz.</div>
        <button class="btn btn-sun" id="paSave" type="button">💾 Alan Bölme Kaydet</button>
      `;

      wrap.querySelector('#paRegen').onclick = () => regenerateGameEntry('patches', 'default');

      const board = document.createElement('div');
      board.className = 'grid-board';
      board.style.gridTemplateColumns = `repeat(${n}, 46px)`;
      for (let r = 0; r < n; r++) {
        for (let c = 0; c < n; c++) {
          const clue = clueMap.get(`${r},${c}`);
          const btn = document.createElement('button');
          btn.type = 'button';
          btn.className = 'cell-btn';
          btn.style.background = rectColorMap.get(`${r},${c}`) || '#fff';
          const shapeGlyph = clue ? ({ square: '□', tall: '▯', wide: '▭', any: '' }[clue.shapeType] || '') : '';
          btn.innerHTML = clue ? `<span>${clue.targetArea}${shapeGlyph}</span>` : '';
          btn.onclick = () => {
            const val = prompt(`(${r + 1},${c + 1}) hücresi için alan sayısı (boş bırakırsanız ipucu silinir):`, clue ? String(clue.targetArea) : '');
            if (val === null) return;
            p.clues = (p.clues || []).filter(x => !(x.row === r && x.col === c));
            const num = parseInt(val.trim(), 10);
            if (!isNaN(num) && num >= 1) {
              const sh = prompt('Şekil türü: any, square, tall, wide', clue ? clue.shapeType : 'any') || 'any';
              p.clues.push({ row: r, col: c, targetArea: num, shapeType: ['square', 'tall', 'wide', 'any'].includes(sh.trim()) ? sh.trim() : 'any' });
            }
            draw();
          };
          board.appendChild(btn);
        }
      }
      wrap.querySelector('#paBoard').appendChild(board);
      wrap.querySelector('#paSave').onclick = () => {
        p.id = selectedDate;
        saveGameEntry('patches', 'default', p);
      };
      renderJsonPanel(wrap, p, (parsed) => saveGameEntry('patches', 'default', parsed));
    }

    draw();
  }

  // Event wiring
  document.querySelectorAll('.pill[data-filter]').forEach(btn => {
    btn.onclick = () => {
      document.querySelectorAll('.pill[data-filter]').forEach(x => x.classList.remove('active'));
      btn.classList.add('active');
      activeFilter = btn.dataset.filter;
      renderCalendar();
    };
  });
  monthFilterEl.onchange = renderCalendar;
  searchEl.oninput = renderCalendar;

  document.querySelectorAll('#gameTabs .tab-btn').forEach(btn => {
    btn.onclick = () => {
      document.querySelectorAll('#gameTabs .tab-btn').forEach(x => x.classList.remove('active'));
      btn.classList.add('active');
      activeGame = btn.dataset.game;
      renderActiveGameEditor();
    };
  });

  document.getElementById('btnSaveMeta').onclick = async () => {
    if (!selectedDate) return;
    try {
      await apiFetch(`day/${selectedDate}/meta`, {
        method: 'PUT',
        body: {
          is_special: document.getElementById('chkSpecial').checked,
          special_note: document.getElementById('inpSpecialNote').value.trim() || null,
        },
      });
      await loadCalendar(true);
      showToast('Özel gün notu güncellendi!');
    } catch (e) {
      showToast(e.message, true);
    }
  };

  document.getElementById('btnRegenDay').onclick = () => {
    if (!selectedDate) return;
    if (!confirm(`${selectedDate} tarihindeki tüm oyunlar otomatik yeniden üretilsin mi?`)) return;
    regenerateGameEntry('all', 'default');
  };

  document.getElementById('btnGenerateYear').onclick = async () => {
    try {
      const now = new Date();
      const todayStr = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}-${String(now.getDate()).padStart(2, '0')}`;
      const res = await apiFetch('generate-year', {
        method: 'POST',
        body: { from: todayStr, days: 365, overwrite_auto: false },
      });
      await loadCalendar(true);
      showToast(`365 gün tamamlandı! Oluşturulan: ${res.created}, Korunan özel: ${res.skipped_admin}`);
    } catch (e) {
      showToast(e.message, true);
    }
  };

  loadCalendar(false);
})();

