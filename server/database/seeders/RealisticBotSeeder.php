<?php

namespace Database\Seeders;

use App\Models\GameScore;
use App\Models\Player;
use Carbon\Carbon;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class RealisticBotSeeder extends Seeder
{
    private const NAMES = [
        'ZekaUstadı', 'Ece_Y', 'AlperenK', 'BeyinFırtınası', 'Kerem34',
        'DenizA', 'ZeynepBulmaca', 'MatematikKurdu', 'HızlıDüşünür', 'ZühtüSever',
        'KraliçeHamlesi', 'PikselAvcısı', 'GizemliZeka', 'Bora_99', 'Canan_T',
        'Mert_Zeka', 'AyseBulmaca', 'Caner_K', 'SelinA', 'BurakAkıl',
        'Elif_D', 'EmreMatematik', 'GamzeY', 'Onur_34', 'DeryaB',
        'Tolga_Z', 'Busra_K', 'KaanUsta', 'Ceren_L', 'YigitBeyin',
        'Esra_T', 'Arda_Kral', 'MelisaV', 'KeremFırtına', 'Tugba_S',
        'SinanZihni', 'Gizem_N', 'BarisLogik', 'Hazal_E', 'VolkanA',
        'IremG', 'Oguzhan_K', 'Fatma_D', 'Serkan_99', 'BusraBulmaca',
        'Deniz_Mavi', 'Merve_A', 'Ege_Zeka', 'Damla_K', 'Umut_Logik',
        'Dilara_S', 'BatuhanB', 'Kubra_T', 'Eren_Z', 'Seyma_K',
        'Alper_G', 'Zeynep_Usta', 'Gokhan_42', 'Hande_B', 'Furkan_S',
        'Sena_M', 'Tarik_Z', 'Bilge_K', 'Koray_V', 'Asli_H',
        'Ilker_D', 'Yasemin_T', 'Cihan_K', 'Begum_S', 'Semih_Z',
        'Ozlem_A', 'Tayfun_R', 'Tugce_K', 'Erdem_M', 'Hale_Z',
        'Hakan_B', 'Seda_N', 'Okan_L', 'Leyla_K', 'Zafer_T',
        'Melike_G', 'Berk_Zeka', 'Ebru_S', 'Doruk_A', 'Ezgi_K',
        'Ufuk_99', 'Nur_B', 'Cem_Logik', 'Sumeyye_T', 'Murat_K',
        'Nilay_M', 'Samet_Z', 'Pelin_A', 'Fatih_G', 'Defne_S',
        'Taner_K', 'Rabia_T', 'Levent_Z', 'Beyza_K', 'Harun_B',
        'Aylin_D', 'Nihat_S', 'Hilal_M', 'Sercan_K', 'Ilayda_T',
        'Mesut_Z', 'Busra_V', 'Eray_A', 'Selvi_K', 'Anil_G',
        'Esma_B', 'Enes_T', 'Selen_Z', 'Gokce_M', 'Halil_K',
        'Berna_D', 'Taha_S', 'Melis_K', 'Ozan_Z', 'Pinar_T',
        'Yunus_B', 'Selcuk_A', 'Sukran_K', 'Ilknur_M', 'Kenan_Z',
        'Ecevit_T', 'Nazli_B', 'Ridvan_K', 'Sibel_S', 'Alim_Z',
        'Gulsah_A', 'Mahmut_T', 'Nihan_K', 'Orkun_B', 'Sevgi_Z',
        'Ramazan_S', 'Tutku_M', 'Sabri_A', 'Zehra_K', 'Utku_T',
        'Yeliz_B', 'Vedat_Z', 'Zuhal_S', 'Yavuz_K', 'Belgin_M',
        'Bilal_A', 'Sevda_T', 'Bora_Z', 'Nergis_K', 'Burcu_S',
    ];

    public function run(): void
    {
        $todayUtc = Carbon::now('UTC');
        $todayDateId = $todayUtc->format('Y-m-d');

        $games = ['pinpoint', 'crossclimb', 'tango', 'zip_path', 'patches'];

        DB::transaction(function () use ($todayUtc, $todayDateId, $games) {
            foreach (self::NAMES as $i => $name) {
                $deviceId = "bot_player_$i";
                $player = Player::updateOrCreate(
                    ['device_id' => $deviceId],
                    [
                        'nickname' => $name,
                        'normalized_nickname' => Player::normalizeNickname($name),
                        'is_bot' => true,
                        'avatar_id' => 'avatar_' . ($i % 12 + 1),
                        'league_tier' => $i < 10 ? 'emerald' : ($i < 30 ? 'gold' : ($i < 70 ? 'silver' : 'stone')),
                        'last_active_at' => $todayUtc->copy()->subMinutes($i * 4),
                    ]
                );

                // --- 1. BUGÜNKÜ OYUNLAR ---
                // Vezirler Kolay
                $kolayDur = 12000 + $i * 350;
                $kolayScore = max(400, 880 - (int)($kolayDur / 500));
                GameScore::updateOrCreate(
                    ['player_id' => $player->id, 'game_type' => 'queens', 'date_id' => $todayDateId, 'difficulty' => 'kolay'],
                    ['score' => $kolayScore, 'duration_ms' => $kolayDur, 'move_count' => 18, 'completed_at' => $todayUtc->copy()->subMinutes(10 + $i)]
                );

                // Vezirler Zor (İlk 100)
                if ($i < 100) {
                    $zorDur = 24000 + $i * 550;
                    $zorScore = max(500, 1160 - (int)($zorDur / 600));
                    GameScore::updateOrCreate(
                        ['player_id' => $player->id, 'game_type' => 'queens', 'date_id' => $todayDateId, 'difficulty' => 'zor'],
                        ['score' => $zorScore, 'duration_ms' => $zorDur, 'move_count' => 24, 'completed_at' => $todayUtc->copy()->subMinutes(15 + $i)]
                    );
                }

                // Vezirler Master (İlk 50)
                if ($i < 50) {
                    $masterDur = 18000 + $i * 850;
                    $masterScore = max(600, 1315 - (int)($masterDur / 700));
                    GameScore::updateOrCreate(
                        ['player_id' => $player->id, 'game_type' => 'queens', 'date_id' => $todayDateId, 'difficulty' => 'master'],
                        ['score' => $masterScore, 'duration_ms' => $masterDur, 'move_count' => 54, 'completed_at' => $todayUtc->copy()->subMinutes(20 + $i)]
                    );
                }

                // Diğer oyunlar (Bugün)
                foreach ($games as $idx => $g) {
                    $dur = 13000 + $i * 400 + ($idx * 300);
                    $sec = (int)($dur / 1000);
                    $sc = max(300, 1950 - ($sec * 8) - ($i * 5));
                    GameScore::updateOrCreate(
                        ['player_id' => $player->id, 'game_type' => $g, 'date_id' => $todayDateId, 'difficulty' => 'default'],
                        ['score' => $sc, 'duration_ms' => $dur, 'move_count' => 10, 'completed_at' => $todayUtc->copy()->subMinutes(8 + $i * 2)]
                    );
                }

                // --- 2. GEÇMİŞ GÜNLER BİRİKİMİ (Haftalık & Aylık Sıralamalar İçin) ---
                for ($dayBack = 1; $dayBack <= 14; $dayBack++) {
                    $pastDate = $todayUtc->copy()->subDays($dayBack);
                    $pastDateId = $pastDate->format('Y-m-d');

                    if ($i > 40 && ($i + $dayBack) % 3 === 0) continue; // Bazı botlar dönüşümlü oynar

                    $pDur = 14000 + $i * 380;
                    $pScore = max(300, 1900 - $i * 6);

                    // Vezirler kolay
                    GameScore::updateOrCreate(
                        ['player_id' => $player->id, 'game_type' => 'queens', 'date_id' => $pastDateId, 'difficulty' => 'kolay'],
                        ['score' => max(400, 850 - $i * 3), 'duration_ms' => $pDur, 'move_count' => 18, 'completed_at' => $pastDate]
                    );

                    // 1-2 ekstra oyun geçmiş günde
                    $pastGame = $games[($i + $dayBack) % count($games)];
                    GameScore::updateOrCreate(
                        ['player_id' => $player->id, 'game_type' => $pastGame, 'date_id' => $pastDateId, 'difficulty' => 'default'],
                        ['score' => $pScore, 'duration_ms' => $pDur, 'move_count' => 10, 'completed_at' => $pastDate]
                    );
                }
            }
        });
    }
}
