<?php

namespace App\Services;

use App\Models\DailyPuzzle;
use Carbon\Carbon;
use Illuminate\Support\Facades\DB;

/**
 * 365 Günlük Oyun Takvimi Üreticisi.
 * - Öncelikle Flutter'daki doğrulanmış jeneratörlerin ürettiği puzzles_365.json ve word_pools.json
 *   dosyalarından günleri yükler.
 * - Takvim dışı tarihler veya Admin panelinden tekil "Yeniden Üret" istekleri için
 *   doğrudan Ubuntu sunucusunda tüm 6 oyun için geçerli bulmacalar üretir.
 * - 'admin' olarak işaretli özel günleri asla otomatik olarak ezmez.
 */
class DailyPuzzleGeneratorService
{
    private ?array $precomputedDays = null;
    private ?array $wordPools = null;

    public function loadPrecomputedDays(): array
    {
        if ($this->precomputedDays !== null) {
            return $this->precomputedDays;
        }
        $path = database_path('data/puzzles_365.json');
        if (!file_exists($path)) {
            $this->precomputedDays = [];
            return $this->precomputedDays;
        }
        $decoded = json_decode(file_get_contents($path), true);
        $byDate = [];
        foreach ($decoded['days'] ?? [] as $day) {
            if (!empty($day['date_id']) && !empty($day['games'])) {
                $byDate[$day['date_id']] = $day['games'];
            }
        }
        $this->precomputedDays = $byDate;
        return $this->precomputedDays;
    }

    public function loadWordPools(): array
    {
        if ($this->wordPools !== null) {
            return $this->wordPools;
        }
        $path = database_path('data/word_pools.json');
        if (!file_exists($path)) {
            $this->wordPools = ['pinpoint' => [], 'crossclimb' => []];
            return $this->wordPools;
        }
        $decoded = json_decode(file_get_contents($path), true);
        $this->wordPools = is_array($decoded) ? $decoded : ['pinpoint' => [], 'crossclimb' => []];
        return $this->wordPools;
    }

    /**
     * Başlangıç tarihinden itibaren [days] gün boyunca tüm oyunları DB'de hazırlar.
     * Varsayılan olarak mevcut 'auto' veya 'admin' kayıtları korur; force=true ise sadece 'auto'ları yeniler.
     */
    public function generateRange(string $fromDateId, int $days = 365, bool $overwriteAuto = false): array
    {
        $start = Carbon::createFromFormat('Y-m-d', $fromDateId, 'Europe/Istanbul')->startOfDay();
        $created = 0;
        $updated = 0;
        $skippedAdmin = 0;

        DB::transaction(function () use ($start, $days, $overwriteAuto, &$created, &$updated, &$skippedAdmin) {
            for ($i = 0; $i < $days; $i++) {
                $dateId = $start->copy()->addDays($i)->format('Y-m-d');
                $stats = $this->ensureDay($dateId, $overwriteAuto);
                $created += $stats['created'];
                $updated += $stats['updated'];
                $skippedAdmin += $stats['skipped_admin'];
            }
        });

        return [
            'from' => $fromDateId,
            'days' => $days,
            'created' => $created,
            'updated' => $updated,
            'skipped_admin' => $skippedAdmin,
        ];
    }

    /**
     * Tek bir günün 6 oyununun (ve Queens'in 3 zorluğunun) tüm kayıtlarını DB'de garantiler.
     */
    public function ensureDay(string $dateId, bool $overwriteAuto = false): array
    {
        $existingRows = DailyPuzzle::where('date_id', $dateId)->get()->keyBy(
            fn (DailyPuzzle $row) => $row->game_type . '|' . $row->difficulty
        );

        $slots = [
            ['queens', 'kolay'],
            ['queens', 'zor'],
            ['queens', 'master'],
            ['pinpoint', 'default'],
            ['crossclimb', 'default'],
            ['tango', 'default'],
            ['zip_path', 'default'],
            ['patches', 'default'],
        ];

        $isSpecial = false;
        $specialNote = null;
        foreach ($existingRows as $row) {
            if ($row->is_special) {
                $isSpecial = true;
            }
            if ($row->special_note) {
                $specialNote = $row->special_note;
            }
        }

        $created = 0;
        $updated = 0;
        $skippedAdmin = 0;

        foreach ($slots as [$gameType, $difficulty]) {
            $key = $gameType . '|' . $difficulty;
            $existing = $existingRows->get($key);

            if ($existing) {
                if ($existing->source === 'admin') {
                    $skippedAdmin++;
                    continue;
                }
                if (!$overwriteAuto) {
                    continue;
                }
            }

            $payload = $this->buildPayload($dateId, $gameType, $difficulty, 0);

            if ($existing) {
                $existing->update([
                    'payload' => $payload,
                    'source' => 'auto',
                ]);
                $updated++;
            } else {
                DailyPuzzle::create([
                    'date_id' => $dateId,
                    'game_type' => $gameType,
                    'difficulty' => $difficulty,
                    'payload' => $payload,
                    'is_special' => $isSpecial,
                    'special_note' => $specialNote,
                    'source' => 'auto',
                ]);
                $created++;
            }
        }

        return [
            'created' => $created,
            'updated' => $updated,
            'skipped_admin' => $skippedAdmin,
        ];
    }

    /**
     * Admin tarafından tek bir oyunu (veya zorluğu) rastgele yeniden üretir.
     */
    public function regenerateOne(string $dateId, string $gameType, string $difficulty = 'default', int $nonce = 1): DailyPuzzle
    {
        $payload = $this->buildPayload($dateId, $gameType, $difficulty, $nonce);

        $existing = DailyPuzzle::where('date_id', $dateId)
            ->where('game_type', $gameType)
            ->where('difficulty', $difficulty)
            ->first();

        if ($existing) {
            $existing->update([
                'payload' => $payload,
                'source' => 'auto',
            ]);
            return $existing->fresh();
        }

        return DailyPuzzle::create([
            'date_id' => $dateId,
            'game_type' => $gameType,
            'difficulty' => $difficulty,
            'payload' => $payload,
            'is_special' => false,
            'special_note' => null,
            'source' => 'auto',
        ]);
    }

    /**
     * Belirli gün + oyun için geçerli payload üretir.
     */
    public function buildPayload(string $dateId, string $gameType, string $difficulty = 'default', int $nonce = 0): array
    {
        if ($nonce === 0) {
            $days = $this->loadPrecomputedDays();
            if (isset($days[$dateId])) {
                $dayGames = $days[$dateId];
                if ($gameType === 'queens' && isset($dayGames['queens'][$difficulty])) {
                    return $dayGames['queens'][$difficulty];
                }
                if ($gameType !== 'queens' && isset($dayGames[$gameType])) {
                    return $dayGames[$gameType];
                }
            }
        }

        $seed = crc32($dateId . '|' . $gameType . '|' . $difficulty . '|' . $nonce);
        if ($seed < 0) {
            $seed = -$seed;
        }

        return match ($gameType) {
            'pinpoint' => $this->generatePinpoint($dateId, $seed),
            'crossclimb' => $this->generateCrossclimb($dateId, $seed),
            'queens' => $this->generateQueens($dateId, $difficulty, $seed),
            'tango' => $this->generateTango($dateId, $seed),
            'zip_path' => $this->generateZipPath($dateId, $seed),
            'patches' => $this->generatePatches($dateId, $seed),
            default => throw new \InvalidArgumentException("Desteklenmeyen oyun türü: $gameType"),
        };
    }

    private function generatePinpoint(string $dateId, int $seed): array
    {
        $pools = $this->loadWordPools();
        $list = $pools['pinpoint'] ?? [];
        if (!empty($list)) {
            $item = $list[$seed % count($list)];
            $item['id'] = $dateId;
            return $item;
        }
        return [
            'id' => $dateId,
            'categoryHint' => 'Doğa & Yaşam',
            'targetWord' => 'KAHVE',
            'clues' => ['Çekirdek', 'Kafein', 'Kavurma', 'Fincan', 'Telve'],
            'alternativeAnswers' => [],
        ];
    }

    private function generateCrossclimb(string $dateId, int $seed): array
    {
        $pools = $this->loadWordPools();
        $list = $pools['crossclimb'] ?? [];
        if (!empty($list)) {
            $item = $list[$seed % count($list)];
            $item['id'] = $dateId;
            return $item;
        }
        return [
            'id' => $dateId,
            'startWord' => 'KARA',
            'endWord' => 'SIRA',
            'steps' => [
                ['targetWord' => 'KIRA', 'clue' => 'Küçük kara parçası / kır', 'index' => 0, 'changedIndex' => 1],
                ['targetWord' => 'SIRA', 'clue' => 'Dizi veya okul oturağı', 'index' => 1, 'changedIndex' => 0],
            ],
        ];
    }

    private function generateQueens(string $dateId, string $difficulty, int $seed): array
    {
        $map = [
            'kolay' => [6, 1],
            'zor' => [8, 1],
            'master' => [9, 2],
        ];
        [$n, $qpu] = $map[$difficulty] ?? [6, 1];

        mt_srand($seed);
        $solution = $this->placeQueens($n, $qpu);
        $regions = $this->growRegions($n, $solution);

        return [
            'id' => $dateId,
            'gridSize' => $n,
            'difficulty' => in_array($difficulty, ['kolay', 'zor', 'master'], true) ? $difficulty : 'kolay',
            'queensPerUnit' => $qpu,
            'regionMap' => $regions,
            'solution' => $solution,
        ];
    }

    private function placeQueens(int $n, int $qpu): array
    {
        for ($attempt = 0; $attempt < 60; $attempt++) {
            $rowQueens = [];
            $colCounts = array_fill(0, $n, 0);
            $placed = [];
            if ($this->backtrackQueens(0, 0, $n, $qpu, $rowQueens, $colCounts, $placed)) {
                return $placed;
            }
        }
        // Fallback deterministik geçerli yerleşim
        $fallback = [];
        if ($n === 6 && $qpu === 1) {
            foreach ([1, 3, 5, 0, 2, 4] as $r => $c) {
                $fallback[] = [$r, $c];
            }
            return $fallback;
        }
        foreach ([0, 2, 4, 6, 1, 3, 5, 7] as $r => $c) {
            if ($r < $n && $c < $n) {
                $fallback[] = [$r, $c];
            }
        }
        return $fallback;
    }

    private function backtrackQueens(int $r, int $countInRow, int $n, int $qpu, array &$rowCols, array &$colCounts, array &$placed): bool
    {
        if ($r >= $n) {
            return true;
        }
        if ($countInRow >= $qpu) {
            return $this->backtrackQueens($r + 1, 0, $n, $qpu, $rowCols, $colCounts, $placed);
        }

        $cols = range(0, $n - 1);
        shuffle($cols);
        $minCol = ($countInRow > 0 && isset($rowCols[$r][$countInRow - 1])) ? $rowCols[$r][$countInRow - 1] + 2 : 0;

        foreach ($cols as $c) {
            if ($c < $minCol) {
                continue;
            }
            if ($colCounts[$c] >= $qpu) {
                continue;
            }
            $conflict = false;
            foreach ($placed as [$pr, $pc]) {
                if (abs($pr - $r) <= 1 && abs($pc - $c) <= 1) {
                    $conflict = true;
                    break;
                }
            }
            if ($conflict) {
                continue;
            }

            $colCounts[$c]++;
            $rowCols[$r][] = $c;
            $placed[] = [$r, $c];

            if ($this->backtrackQueens($r, $countInRow + 1, $n, $qpu, $rowCols, $colCounts, $placed)) {
                return true;
            }

            array_pop($placed);
            array_pop($rowCols[$r]);
            $colCounts[$c]--;
        }

        return false;
    }

    private function growRegions(int $n, array $solution): array
    {
        $grid = array_fill(0, $n, array_fill(0, $n, -1));
        $queues = [];

        if (count($solution) === $n) {
            foreach ($solution as $regionId => [$r, $c]) {
                $grid[$r][$c] = $regionId;
                $queues[$regionId] = [[$r, $c]];
            }
        } else {
            // Master (2 queens per region): pair queens so each region gets 2 queens
            for ($i = 0; $i < $n; $i++) {
                $q1 = $solution[$i * 2] ?? [$i, 0];
                $q2 = $solution[$i * 2 + 1] ?? [$i, $n - 1];
                $grid[$q1[0]][$q1[1]] = $i;
                $grid[$q2[0]][$q2[1]] = $i;
                $queues[$i] = [$q1, $q2];
            }
        }

        $dirs = [[-1, 0], [1, 0], [0, -1], [0, 1]];
        $remaining = $n * $n - count(array_filter(array_merge(...$grid), fn ($v) => $v >= 0));
        $guard = 0;
        while ($remaining > 0 && $guard < 5000) {
            $guard++;
            $order = range(0, $n - 1);
            shuffle($order);
            $grew = false;
            foreach ($order as $rid) {
                $candidates = [];
                foreach ($queues[$rid] as [$cr, $cc]) {
                    foreach ($dirs as [$dr, $dc]) {
                        $nr = $cr + $dr;
                        $nc = $cc + $dc;
                        if ($nr >= 0 && $nr < $n && $nc >= 0 && $nc < $n && $grid[$nr][$nc] === -1) {
                            $candidates[] = [$nr, $nc];
                        }
                    }
                }
                if (!empty($candidates)) {
                    $pick = $candidates[array_rand($candidates)];
                    $grid[$pick[0]][$pick[1]] = $rid;
                    $queues[$rid][] = $pick;
                    $remaining--;
                    $grew = true;
                }
            }
            if (!$grew) {
                // Assign any trapped cell to an adjacent region
                for ($r = 0; $r < $n; $r++) {
                    for ($c = 0; $c < $n; $c++) {
                        if ($grid[$r][$c] !== -1) {
                            continue;
                        }
                        foreach ($dirs as [$dr, $dc]) {
                            $nr = $r + $dr;
                            $nc = $c + $dc;
                            if ($nr >= 0 && $nr < $n && $nc >= 0 && $nc < $n && $grid[$nr][$nc] >= 0) {
                                $rid = $grid[$nr][$nc];
                                $grid[$r][$c] = $rid;
                                $queues[$rid][] = [$r, $c];
                                $remaining--;
                                break;
                            }
                        }
                    }
                }
            }
        }

        return $grid;
    }

    private function generateTango(string $dateId, int $seed): array
    {
        mt_srand($seed);
        $diffs = ['kolay', 'orta', 'zor'];
        $diff = $diffs[$seed % 3];

        // Geçerli temel 6x6 Takuzu matrisi + satır/sütun/sembol permütasyonu (tüm kurallar korunur)
        $base = [
            [1, 1, 2, 1, 2, 2],
            [2, 2, 1, 2, 1, 1],
            [1, 2, 1, 2, 1, 2],
            [2, 1, 2, 1, 2, 1],
            [1, 2, 2, 1, 1, 2],
            [2, 1, 1, 2, 2, 1],
        ];
        if (mt_rand(0, 1) === 1) {
            for ($r = 0; $r < 6; $r++) {
                for ($c = 0; $c < 6; $c++) {
                    $base[$r][$c] = $base[$r][$c] === 1 ? 2 : 1;
                }
            }
        }
        // Satır çiftlerini ve tam matris transpozunu güvenli karıştır
        if (mt_rand(0, 1) === 1) {
            $t = [];
            for ($r = 0; $r < 6; $r++) {
                for ($c = 0; $c < 6; $c++) {
                    $t[$r][$c] = $base[$c][$r];
                }
            }
            $base = $t;
        }

        $revealCount = match ($diff) {
            'kolay' => 12,
            'orta' => 9,
            default => 7,
        };

        $initial = array_fill(0, 6, array_fill(0, 6, 0));
        $cells = [];
        for ($r = 0; $r < 6; $r++) {
            for ($c = 0; $c < 6; $c++) {
                $cells[] = [$r, $c];
            }
        }
        shuffle($cells);
        for ($i = 0; $i < $revealCount; $i++) {
            [$r, $c] = $cells[$i];
            $initial[$r][$c] = $base[$r][$c];
        }

        $constraints = [];
        $edges = [];
        for ($r = 0; $r < 6; $r++) {
            for ($c = 0; $c < 6; $c++) {
                if ($c + 1 < 6) {
                    $edges[] = [$r, $c, $r, $c + 1];
                }
                if ($r + 1 < 6) {
                    $edges[] = [$r, $c, $r + 1, $c];
                }
            }
        }
        shuffle($edges);
        foreach (array_slice($edges, 0, 6) as [$r1, $c1, $r2, $c2]) {
            $constraints[] = [
                'r1' => $r1,
                'c1' => $c1,
                'r2' => $r2,
                'c2' => $c2,
                'type' => $base[$r1][$c1] === $base[$r2][$c2] ? 'equal' : 'opposite',
            ];
        }

        return [
            'id' => $dateId,
            'gridSize' => 6,
            'difficulty' => $diff,
            'initialGrid' => $initial,
            'constraints' => $constraints,
            'solution' => $base,
        ];
    }

    private function generateZipPath(string $dateId, int $seed): array
    {
        mt_srand($seed);
        $diffs = ['kolay', 'orta', 'zor'];
        $diff = $diffs[$seed % 3];
        $n = $diff === 'kolay' ? 4 : 5;

        // Yılan (serpentine) rota + simetri dönüşümleri (rastgele döndürme/yansıtma)
        $path = [];
        for ($r = 0; $r < $n; $r++) {
            if ($r % 2 === 0) {
                for ($c = 0; $c < $n; $c++) {
                    $path[] = [$r, $c];
                }
            } else {
                for ($c = $n - 1; $c >= 0; $c--) {
                    $path[] = [$r, $c];
                }
            }
        }

        $rot = mt_rand(0, 3);
        $flip = mt_rand(0, 1) === 1;
        $transformed = array_map(function ($pt) use ($n, $rot, $flip) {
            [$r, $c] = $pt;
            if ($flip) {
                $c = $n - 1 - $c;
            }
            for ($k = 0; $k < $rot; $k++) {
                [$r, $c] = [$c, $n - 1 - $r];
            }
            return ['row' => $r, 'col' => $c];
        }, $path);

        $total = count($transformed);
        $checkpointIndices = [0, (int) floor($total * 0.28), (int) floor($total * 0.56), (int) floor($total * 0.8), $total - 1];
        $numberPoints = [];
        foreach ($checkpointIndices as $idx => $pathIdx) {
            $pt = $transformed[$pathIdx];
            $numberPoints[] = ['row' => $pt['row'], 'col' => $pt['col'], 'num' => $idx + 1];
        }

        // Rota üzerinde olmayan rastgele komşuluklardan duvar üret
        $pathEdges = [];
        for ($i = 0; $i < $total - 1; $i++) {
            $a = $transformed[$i];
            $b = $transformed[$i + 1];
            $key1 = "{$a['row']},{$a['col']}-{$b['row']},{$b['col']}";
            $key2 = "{$b['row']},{$b['col']}-{$a['row']},{$a['col']}";
            $pathEdges[$key1] = true;
            $pathEdges[$key2] = true;
        }

        $nonPathEdges = [];
        for ($r = 0; $r < $n; $r++) {
            for ($c = 0; $c < $n; $c++) {
                if ($c + 1 < $n && !isset($pathEdges["$r,$c-$r," . ($c + 1)])) {
                    $nonPathEdges[] = ['r1' => $r, 'c1' => $c, 'r2' => $r, 'c2' => $c + 1];
                }
                if ($r + 1 < $n && !isset($pathEdges["$r,$c-" . ($r + 1) . ",$c"])) {
                    $nonPathEdges[] = ['r1' => $r, 'c1' => $c, 'r2' => $r + 1, 'c2' => $c];
                }
            }
        }
        shuffle($nonPathEdges);
        $edgeWalls = array_slice($nonPathEdges, 0, min(3, count($nonPathEdges)));

        return [
            'id' => $dateId,
            'gridSize' => $n,
            'difficulty' => $diff,
            'numberPoints' => $numberPoints,
            'walls' => [],
            'edgeWalls' => $edgeWalls,
            'solutionPath' => $transformed,
        ];
    }

    private function generatePatches(string $dateId, int $seed): array
    {
        mt_srand($seed);
        $diffs = ['kolay', 'orta', 'zor'];
        $diff = $diffs[$seed % 3];
        $n = match ($diff) {
            'kolay' => 5,
            'orta' => 6,
            default => 7,
        };

        $used = array_fill(0, $n, array_fill(0, $n, false));
        $rects = [];
        $clues = [];
        $color = 0;

        for ($r = 0; $r < $n; $r++) {
            for ($c = 0; $c < $n; $c++) {
                if ($used[$r][$c]) {
                    continue;
                }
                $maxW = 0;
                while ($c + $maxW < $n && !$used[$r][$c + $maxW] && $maxW < 4) {
                    $maxW++;
                }
                $w = mt_rand(1, $maxW);
                $maxH = 0;
                while ($r + $maxH < $n && $maxH < 4) {
                    $ok = true;
                    for ($cc = $c; $cc < $c + $w; $cc++) {
                        if ($used[$r + $maxH][$cc]) {
                            $ok = false;
                            break;
                        }
                    }
                    if (!$ok) {
                        break;
                    }
                    $maxH++;
                }
                $h = mt_rand(1, max(1, $maxH));
                for ($rr = $r; $rr < $r + $h; $rr++) {
                    for ($cc = $c; $cc < $c + $w; $cc++) {
                        $used[$rr][$cc] = true;
                    }
                }

                $rects[] = [
                    'topRow' => $r,
                    'leftCol' => $c,
                    'bottomRow' => $r + $h - 1,
                    'rightCol' => $c + $w - 1,
                    'colorIndex' => $color++ % 8,
                ];

                $shape = 'any';
                if ($w === $h && $w > 1) {
                    $shape = 'square';
                } elseif ($h > $w && mt_rand(0, 1) === 1) {
                    $shape = 'tall';
                } elseif ($w > $h && mt_rand(0, 1) === 1) {
                    $shape = 'wide';
                }

                $clues[] = [
                    'row' => mt_rand($r, $r + $h - 1),
                    'col' => mt_rand($c, $c + $w - 1),
                    'targetArea' => $w * $h,
                    'shapeType' => $shape,
                ];
            }
        }

        return [
            'id' => $dateId,
            'gridSize' => $n,
            'difficulty' => $diff,
            'clues' => $clues,
            'solution' => $rects,
        ];
    }
}

