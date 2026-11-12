<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\DailyPuzzle;
use App\Services\DailyPuzzleGeneratorService;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class AdminPuzzleController extends Controller
{
    private function authorizeAdmin(Request $request): ?JsonResponse
    {
        $configuredSecret = (string) (config('services.zuhtu.admin_api_secret') ?: env('ADMIN_API_SECRET', ''));
        if ($configuredSecret === '') {
            return response()->json([
                'status' => 'error',
                'message' => 'Sunucuda ADMIN_API_SECRET tanımlı değil.',
            ], 503);
        }

        $provided = (string) ($request->header('X-Admin-Secret') ?: $request->bearerToken() ?: '');
        if ($provided === '' || !hash_equals($configuredSecret, $provided)) {
            return response()->json([
                'status' => 'error',
                'message' => 'Yetkisiz admin erişimi.',
            ], 401);
        }

        return null;
    }

    public function calendar(Request $request, DailyPuzzleGeneratorService $generator): JsonResponse
    {
        if ($deny = $this->authorizeAdmin($request)) {
            return $deny;
        }

        $from = $request->query('from') ?: Carbon::now('Europe/Istanbul')->format('Y-m-d');
        $days = max(1, min(400, (int) ($request->query('days') ?: 365)));

        if (!preg_match('/^\d{4}-\d{2}-\d{2}$/', $from)) {
            return response()->json(['status' => 'error', 'message' => 'Geçersiz başlangıç tarihi.'], 422);
        }

        $start = Carbon::createFromFormat('Y-m-d', $from, 'Europe/Istanbul')->startOfDay();
        $endDateId = $start->copy()->addDays($days - 1)->format('Y-m-d');

        // Veritabanında henüz hiç 365 günlük kayıt yoksa eksik günleri tamamla
        $countInRange = DailyPuzzle::whereBetween('date_id', [$from, $endDateId])
            ->distinct('date_id')
            ->count('date_id');
        if ($countInRange < min($days, 30)) {
            $generator->generateRange($from, $days, false);
        }

        $rows = DailyPuzzle::whereBetween('date_id', [$from, $endDateId])
            ->orderBy('date_id')
            ->get()
            ->groupBy('date_id');

        $calendar = [];
        for ($i = 0; $i < $days; $i++) {
            $dateId = $start->copy()->addDays($i)->format('Y-m-d');
            $dayRows = $rows->get($dateId);

            if (!$dayRows || $dayRows->isEmpty()) {
                $generator->ensureDay($dateId, false);
                $dayRows = DailyPuzzle::where('date_id', $dateId)->get();
            }

            $isSpecial = false;
            $specialNote = null;
            $adminCount = 0;
            $sources = [];
            $summary = [];

            foreach ($dayRows as $r) {
                if ($r->is_special) {
                    $isSpecial = true;
                }
                if ($r->special_note) {
                    $specialNote = $r->special_note;
                }
                if ($r->source === 'admin') {
                    $adminCount++;
                }
                $key = $r->game_type === 'queens' ? "queens_{$r->difficulty}" : $r->game_type;
                $sources[$key] = $r->source;

                $p = $r->payload ?? [];
                if ($r->game_type === 'pinpoint') {
                    $summary['pinpoint'] = $p['targetWord'] ?? '-';
                } elseif ($r->game_type === 'crossclimb') {
                    $summary['crossclimb'] = ($p['startWord'] ?? '?') . ' → ' . ($p['endWord'] ?? '?');
                } elseif ($r->game_type === 'zip_path') {
                    $summary['zip_path'] = ($p['gridSize'] ?? 5) . '×' . ($p['gridSize'] ?? 5);
                } elseif ($r->game_type === 'tango') {
                    $summary['tango'] = strtoupper((string) ($p['difficulty'] ?? 'orta'));
                } elseif ($r->game_type === 'patches') {
                    $summary['patches'] = ($p['gridSize'] ?? 6) . '×' . ($p['gridSize'] ?? 6);
                }
            }

            $calendar[] = [
                'date_id' => $dateId,
                'is_special' => $isSpecial,
                'special_note' => $specialNote,
                'admin_count' => $adminCount,
                'sources' => $sources,
                'summary' => $summary,
            ];
        }

        return response()->json([
            'status' => 'success',
            'from' => $from,
            'days' => $days,
            'calendar' => $calendar,
        ]);
    }

    public function showDay(Request $request, string $dateId, DailyPuzzleGeneratorService $generator): JsonResponse
    {
        if ($deny = $this->authorizeAdmin($request)) {
            return $deny;
        }
        if (!preg_match('/^\d{4}-\d{2}-\d{2}$/', $dateId)) {
            return response()->json(['status' => 'error', 'message' => 'Geçersiz tarih formatı.'], 422);
        }

        $generator->ensureDay($dateId, false);
        $rows = DailyPuzzle::where('date_id', $dateId)->get();

        $isSpecial = false;
        $specialNote = null;
        $entries = [];

        foreach ($rows as $row) {
            if ($row->is_special) {
                $isSpecial = true;
            }
            if ($row->special_note) {
                $specialNote = $row->special_note;
            }
            $entries[] = [
                'game_type' => $row->game_type,
                'difficulty' => $row->difficulty,
                'source' => $row->source,
                'payload' => $row->payload,
                'updated_at' => $row->updated_at?->toIso8601String(),
            ];
        }

        return response()->json([
            'status' => 'success',
            'date_id' => $dateId,
            'is_special' => $isSpecial,
            'special_note' => $specialNote,
            'entries' => $entries,
        ]);
    }

    public function updateDayMeta(Request $request, string $dateId, DailyPuzzleGeneratorService $generator): JsonResponse
    {
        if ($deny = $this->authorizeAdmin($request)) {
            return $deny;
        }
        if (!preg_match('/^\d{4}-\d{2}-\d{2}$/', $dateId)) {
            return response()->json(['status' => 'error', 'message' => 'Geçersiz tarih formatı.'], 422);
        }

        $validated = $request->validate([
            'is_special' => 'required|boolean',
            'special_note' => 'nullable|string|max:255',
        ]);

        $generator->ensureDay($dateId, false);
        DailyPuzzle::where('date_id', $dateId)->update([
            'is_special' => $validated['is_special'],
            'special_note' => $validated['special_note'] ?: null,
        ]);

        return response()->json([
            'status' => 'success',
            'date_id' => $dateId,
            'is_special' => $validated['is_special'],
            'special_note' => $validated['special_note'] ?: null,
        ]);
    }

    public function updateGame(Request $request, string $dateId, string $gameType, DailyPuzzleGeneratorService $generator): JsonResponse
    {
        if ($deny = $this->authorizeAdmin($request)) {
            return $deny;
        }
        if ($gameType === 'zipPath') {
            $gameType = 'zip_path';
        }
        if (!preg_match('/^\d{4}-\d{2}-\d{2}$/', $dateId)) {
            return response()->json(['status' => 'error', 'message' => 'Geçersiz tarih formatı.'], 422);
        }

        $validated = $request->validate([
            'difficulty' => 'nullable|string|in:default,kolay,zor,master',
            'payload' => 'required|array',
            'is_special' => 'nullable|boolean',
            'special_note' => 'nullable|string|max:255',
        ]);

        $difficulty = $validated['difficulty'] ?: ($gameType === 'queens' ? 'kolay' : 'default');
        $payload = $validated['payload'];
        $payload['id'] = $dateId;

        if ($error = $this->validateGamePayload($gameType, $payload)) {
            return response()->json([
                'status' => 'error',
                'message' => $error,
            ], 422);
        }

        $generator->ensureDay($dateId, false);

        $row = DailyPuzzle::where('date_id', $dateId)
            ->where('game_type', $gameType)
            ->where('difficulty', $difficulty)
            ->first();

        $metaUpdate = [];
        if (array_key_exists('is_special', $validated)) {
            $metaUpdate['is_special'] = (bool) $validated['is_special'];
        }
        if (array_key_exists('special_note', $validated)) {
            $metaUpdate['special_note'] = $validated['special_note'] ?: null;
        }

        if ($row) {
            $row->update(array_merge([
                'payload' => $payload,
                'source' => 'admin',
            ], $metaUpdate));
        } else {
            $row = DailyPuzzle::create(array_merge([
                'date_id' => $dateId,
                'game_type' => $gameType,
                'difficulty' => $difficulty,
                'payload' => $payload,
                'source' => 'admin',
                'is_special' => false,
            ], $metaUpdate));
        }

        if (!empty($metaUpdate)) {
            DailyPuzzle::where('date_id', $dateId)->update($metaUpdate);
        }

        return response()->json([
            'status' => 'success',
            'date_id' => $dateId,
            'game_type' => $gameType,
            'difficulty' => $difficulty,
            'source' => 'admin',
            'payload' => $row->fresh()->payload,
        ]);
    }

    public function regenerate(Request $request, string $dateId, DailyPuzzleGeneratorService $generator): JsonResponse
    {
        if ($deny = $this->authorizeAdmin($request)) {
            return $deny;
        }
        if (!preg_match('/^\d{4}-\d{2}-\d{2}$/', $dateId)) {
            return response()->json(['status' => 'error', 'message' => 'Geçersiz tarih formatı.'], 422);
        }

        $validated = $request->validate([
            'game_type' => 'required|string|in:queens,pinpoint,crossclimb,tango,zip_path,patches,all',
            'difficulty' => 'nullable|string|in:default,kolay,zor,master',
        ]);

        $nonce = random_int(1, 999999);
        $gameType = $validated['game_type'];
        $difficulty = $validated['difficulty'] ?: ($gameType === 'queens' ? 'kolay' : 'default');

        if ($gameType === 'all') {
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
            foreach ($slots as [$gt, $df]) {
                $generator->regenerateOne($dateId, $gt, $df, $nonce);
            }
            return response()->json(['status' => 'success', 'date_id' => $dateId]);
        }

        $updated = $generator->regenerateOne($dateId, $gameType, $difficulty, $nonce);
        return response()->json([
            'status' => 'success',
            'date_id' => $dateId,
            'game_type' => $gameType,
            'difficulty' => $difficulty,
            'source' => $updated->source,
            'payload' => $updated->payload,
        ]);
    }

    public function generateYear(Request $request, DailyPuzzleGeneratorService $generator): JsonResponse
    {
        if ($deny = $this->authorizeAdmin($request)) {
            return $deny;
        }

        $from = $request->input('from') ?: Carbon::now('Europe/Istanbul')->format('Y-m-d');
        $days = max(1, min(400, (int) ($request->input('days') ?: 365)));
        $overwriteAuto = (bool) $request->input('overwrite_auto', false);

        if (!preg_match('/^\d{4}-\d{2}-\d{2}$/', $from)) {
            return response()->json(['status' => 'error', 'message' => 'Geçersiz başlangıç tarihi.'], 422);
        }

        $stats = $generator->generateRange($from, $days, $overwriteAuto);
        return response()->json(array_merge(['status' => 'success'], $stats));
    }

    private function validateGamePayload(string $gameType, array $p): ?string
    {
        if ($gameType === 'pinpoint') {
            if (trim((string) ($p['targetWord'] ?? '')) === '') {
                return 'Pinpoint hedef kelimesi boş olamaz.';
            }
            $clues = array_values(array_filter($p['clues'] ?? [], fn ($c) => trim((string) $c) !== ''));
            if (count($clues) < 3) {
                return 'Pinpoint için en az 3 ipucu girilmelidir.';
            }
            return null;
        }

        if ($gameType === 'crossclimb') {
            $start = mb_strtoupper(trim((string) ($p['startWord'] ?? '')), 'UTF-8');
            $end = mb_strtoupper(trim((string) ($p['endWord'] ?? '')), 'UTF-8');
            $steps = $p['steps'] ?? [];
            if ($start === '' || $end === '' || count($steps) < 2) {
                return 'Crossclimb için başlangıç, bitiş ve en az 2 ara adım gereklidir.';
            }
            $prev = $start;
            foreach ($steps as $idx => $s) {
                $w = mb_strtoupper(trim((string) ($s['targetWord'] ?? '')), 'UTF-8');
                if (mb_strlen($w, 'UTF-8') !== mb_strlen($prev, 'UTF-8')) {
                    return ($idx + 1) . '. adımdaki kelime uzunluğu uyuşmuyor.';
                }
                if (trim((string) ($s['clue'] ?? '')) === '') {
                    return ($idx + 1) . '. adımdaki ipucu boş olamaz.';
                }
                $diff = 0;
                $len = mb_strlen($w, 'UTF-8');
                for ($i = 0; $i < $len; $i++) {
                    if (mb_substr($prev, $i, 1, 'UTF-8') !== mb_substr($w, $i, 1, 'UTF-8')) {
                        $diff++;
                    }
                }
                if ($diff !== 1) {
                    return "'{$prev}' ile '{$w}' arasında tam 1 harf farkı olmalıdır (şu an {$diff} harf farklı).";
                }
                $prev = $w;
            }
            if ($prev !== $end) {
                return "Son adım kelimesi ('{$prev}') bitiş kelimesi ('{$end}') ile aynı olmalıdır.";
            }
            return null;
        }

        if ($gameType === 'zip_path') {
            $n = (int) ($p['gridSize'] ?? 0);
            if ($n < 4 || $n > 7) {
                return 'Sayı Yolu boyutu 4 ile 7 arasında olmalıdır.';
            }
            $points = $p['numberPoints'] ?? [];
            if (count($points) < 2) {
                return 'Sayı Yolu için en az 2 numaralı nokta gereklidir.';
            }
            return null;
        }

        if ($gameType === 'queens') {
            $n = (int) ($p['gridSize'] ?? 0);
            $regions = $p['regionMap'] ?? [];
            $solution = $p['solution'] ?? [];
            if ($n < 4 || count($regions) !== $n || count($solution) < $n) {
                return 'Vezirler tablo boyutu, bölgeler ve çözüm eksik.';
            }
            return null;
        }

        if ($gameType === 'tango') {
            $n = (int) ($p['gridSize'] ?? 0);
            $grid = $p['initialGrid'] ?? [];
            if ($n !== 6 || count($grid) !== 6) {
                return 'Güneş & Ay tahtası 6x6 olmalıdır.';
            }
            return null;
        }

        if ($gameType === 'patches') {
            $n = (int) ($p['gridSize'] ?? 0);
            $clues = $p['clues'] ?? [];
            if ($n < 4 || $n > 8 || count($clues) < 2) {
                return 'Alan Bölme boyutu ve ipuçları eksik.';
            }
            return null;
        }

        return 'Bilinmeyen oyun türü.';
    }
}

