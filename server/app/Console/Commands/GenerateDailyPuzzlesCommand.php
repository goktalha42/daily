<?php

namespace App\Console\Commands;

use App\Services\DailyPuzzleGeneratorService;
use Carbon\Carbon;
use Illuminate\Console\Command;

class GenerateDailyPuzzlesCommand extends Command
{
    protected $signature = 'puzzles:generate
        {--from= : Başlangıç tarihi (YYYY-MM-DD, varsayılan bugünden 7 gün önce)}
        {--days=373 : Kaç günlük takvim üretileceği}
        {--force : Mevcut auto bulmacaları yeniden üret (admin özelleştirmelerine dokunmaz)}';

    protected $description = '365 günlük Zühtü bulmaca takvimini veritabanında oluşturur.';

    public function handle(DailyPuzzleGeneratorService $generator): int
    {
        $from = $this->option('from')
            ?: Carbon::now('Europe/Istanbul')->subDays(7)->format('Y-m-d');
        $days = (int) $this->option('days');
        $force = (bool) $this->option('force');

        $this->info("Zühtü 365 günlük takvim hazırlanıyor: {$from} (+{$days} gün)...");
        $stats = $generator->generateRange($from, max(1, min(800, $days)), $force);

        $this->info("Tamamlandı! Oluşturulan: {$stats['created']}, Güncellenen: {$stats['updated']}, Korunan Admin Özel: {$stats['skipped_admin']}");
        return self::SUCCESS;
    }
}

