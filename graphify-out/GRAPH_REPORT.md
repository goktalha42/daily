# Graph Report - daily  (2026-11-12)

## Corpus Check
- 226 files · ~215,785 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 75 file(s) not represented in the graph (top: (none) 25, .xml 9, .xcconfig 8)

## Summary
- 3125 nodes · 4802 edges · 177 communities (132 shown, 45 thin omitted)
- Extraction: 98% EXTRACTED · 2% INFERRED · 0% AMBIGUOUS · INFERRED: 85 edges (avg confidence: 0.79)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `122d244e`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- Color Theme & Palette Tokens
- Queens Screen & Solver UI
- Sketch Paper & Notebook Theme
- badge_model.dart
- Weekly League & Bot Engine
- Patches Screen & Grid Division
- Core Sketch Controls & Win Dialog
- Tango Screen & Grid Controls
- Platform App Icons & Assets
- League Promotion Ladder UI
- iOS Runner & Engine Bridge
- Crossclimb Screen & Ladder Tiles
- Zip Path Screen & Wall Grid
- Game Stats & IQ Milestone Service
- Home Screen Hub & Nav Providers
- Pinpoint Screen & Clue Guessing
- Tango Board Models & Rules
- Patches Shape Models & Rectangles
- Network Checker & Connectivity Guard
- Queens Board Models & Regions
- win32_window.cpp
- Linux Desktop Runner & Engine
- home_brain_hero_card.dart
- sketch_badge_icons.dart
- Zip Path Grid & Difficulty Models
- Sketch Decorations & Queens Screen
- Home Screen & Zip Screen
- package:daily_games/games/common/base_game.dart
- Daily Play Service Module
- game_logic_test.dart
- genius_win_dialog.dart
- Win32 Window & Flutter Window
- Ilerleme & Pubspec
- package:daily_games/games/common/base_game.dart
- pinpoint_levels.dart
- queens_lobby_screen.dart
- Win32 Window Module
- package:flutter/material.dart
- Player
- Profile Screen Module
- leaderboard_screen.dart
- Patches Models & Patches Logic
- daily_genius_certificate_dialog.dart
- crossclimb_models.dart
- retention_notification_service.dart
- queens_logic.dart
- leaderboard_service.dart
- App Spacing Module
- Patches Levels Module
- _
- Main & Utils
- BadgeArtType
- Tango Levels Module
- Zip Levels Module
- date_utils.dart
- Queens Levels Module
- settings_screen.dart
- online_guard_widget.dart
- theme_service.dart
- Patches Generator Module
- sound_haptic_service.dart
- package:flutter/services.dart
- package:flutter_riverpod/flutter_riverpod.dart
- MainActivity.kt
- State
- Tango Logic Module
- _
- completed_game_leaderboard_dialog.dart
- time_machine_dialog.dart
- admin.js
- ../../games/common/base_game.dart
- user_avatar_provider.dart
- Illuminate\Database\Schema\Blueprint
- update_prompt_dialog.dart
- package:flutter_test/flutter_test.dart
- badges_screen.dart
- user_avatar.dart
- update_service.dart
- dailyPlayServiceProvider
- api_client.dart
- remote_puzzle_store.dart
- List
- cloud_backup_service.dart
- ConsumerState
- base_game.dart
- Ilerleme & Readme
- User
- package.json
- require
- ApiTest
- Readme Module
- LaunchImage.imageset/README.md
- player_server_stats.dart
- backup_restore_dialog.dart
- composer.json
- scripts
- require-dev
- README.md
- queens_board_painter.dart
- config
- _
- AppServiceProvider
- weekly_brain_report_dialog.dart
- game_card_logos.dart
- psr-4
- nickname_prompt_dialog.dart
- ExampleTest
- Laravel Application
- Laravel Application
- autoload-dev
- extra
- leagueServiceProvider
- head_to_head_share_dialog.dart
- userNicknameProvider
- player_stats_service.dart
- badge_service.dart
- ../theme/app_colors.dart
- daily_social_share_dialog.dart
- app_text_styles.dart
- dart:async
- onboarding_screen.dart
- Map
- puzzle_serializer.dart
- onboarding_and_share_test.dart
- sketch_league_emblems.dart
- Zühtü Zeka Oyunları - Gizlilik Politikası (Privacy Policy)
- Point
- share_card_helper.dart
- _
- GameScore
- SettingsScreen
- DailyPuzzleGeneratorService
- dart:math
- Illuminate\Http\Request
- _
- update_service_test.dart
- 🚀 Daily Games (Zühtü) - Devir Teslim & VPS Geçiş Kılavuzu
- _
- userAvatarProvider
- _
- Map
- PuzzleRepository
- bootstrap/app.php
- admin/auth.php
- DailyPuzzleGeneratorService.php
- DailyPlayState
- clearMemory

## God Nodes (most connected - your core abstractions)
1. `Kara Kalem Eskiz Defteri Design Language` - 37 edges
2. `dailyPlayServiceProvider` - 33 edges
3. `DailyPuzzleGeneratorService` - 29 edges
4. `leaderboardServiceProvider` - 24 edges
5. `Player` - 24 edges
6. `gameStatsServiceProvider` - 23 edges
7. `badgeServiceProvider` - 21 edges
8. `_` - 21 edges
9. `Win32Window` - 21 edges
10. `GameType` - 16 edges

## Surprising Connections (you probably didn't know these)
- `📌 1. Projenin Genel Durumu ve Yapılanlar` --references--> `GameScore`  [INFERRED]
  VPS_KURULUMU_VE_DURUM.md → server/app/Models/GameScore.php
- `📌 1. Projenin Genel Durumu ve Yapılanlar` --references--> `Player`  [INFERRED]
  VPS_KURULUMU_VE_DURUM.md → server/app/Models/Player.php
- `🌐 4. Canlı VPS Sunucu Durumu (AKTİF & ÇALIŞIYOR)` --references--> `RealisticBotSeeder`  [INFERRED]
  VPS_KURULUMU_VE_DURUM.md → server/database/seeders/RealisticBotSeeder.php
- `DailyPlayNotifierTestExt` --extends--> `DailyPlayNotifier`  [EXTRACTED]
  test/past_game_score_and_iq_test.dart → lib/core/services/daily_play_service.dart
- `GameStatsNotifierTestExt` --extends--> `GameStatsNotifier`  [EXTRACTED]
  test/past_game_score_and_iq_test.dart → lib/core/services/game_stats_service.dart

## Import Cycles
- None detected.

## Hyperedges (group relationships)
- **The 6 Daily Puzzle Games** — readme_game_queens, readme_game_tango, readme_game_zip, readme_game_pinpoint, readme_game_crossclimb, readme_game_patches [EXTRACTED 1.00]
- **Zühtü Gamification & Motivation Architecture** — ilerleme_league_system, ilerleme_iq_index_system, ilerleme_steam_badge_system, rozetler_championship_belts, rozetler_streak_badges [INFERRED 0.95]

## Communities (177 total, 45 thin omitted)

### Community 0 - "Color Theme & Palette Tokens"
Cohesion: 0.02
Nodes (85): accentAmber, accentCyan, accentGreen, accentOrange, accentPink, accentPurple, adaptive, AppColors (+77 more)

### Community 1 - "Queens Screen & Solver UI"
Cohesion: 0.03
Nodes (72): activeColor, _activeHintIsWarning, _activeHintMessage, _activeHintTitle, _applyDragToCell, build, _buildCellContent, _buildHintInfoCard (+64 more)

### Community 2 - "Sketch Paper & Notebook Theme"
Cohesion: 0.03
Nodes (53): backgroundColor, borderColor, borderRadius, borderWidth, build, _buildOrganicPath, _buildWobblyPath, centerChild (+45 more)

### Community 3 - "badge_model.dart"
Cohesion: 0.08
Nodes (24): allBadges, artType, BadgeCategory, badgeId, _buildStreakBadges, category, color, DailyBadge (+16 more)

### Community 4 - "Weekly League & Bot Engine"
Cohesion: 0.04
Nodes (56): _allBotNames, apiClient, avatarId, _buildLeaguePlayers, _calculateUserScoreForWeek, _calculateUserWeeklyScore, checkWeekTransition, clearPendingLeagueChange (+48 more)

### Community 5 - "Patches Screen & Grid Division"
Cohesion: 0.05
Nodes (39): build, _buildRuleCard, _buildShapeMiniIcon, _cellFromOffset, _checkState, color, createState, didChangeAppLifecycleState (+31 more)

### Community 6 - "Core Sketch Controls & Win Dialog"
Cohesion: 0.07
Nodes (27): _animController, build, child, color, _ConfettiPainter, _ConfettiParticle, _controller, createState (+19 more)

### Community 7 - "Tango Screen & Grid Controls"
Cohesion: 0.05
Nodes (40): build, _buildRuleCard, _buildSymbol, c, _cachedSolution, _checkState, _conflictDebounceTimer, createState (+32 more)

### Community 9 - "League Promotion Ladder UI"
Cohesion: 0.05
Nodes (37): LeaguePlayer, _animController, backgroundColor, barBackgroundColor, _buildRankWidget, _buildWobblyRect, color, createState (+29 more)

### Community 10 - "iOS Runner & Engine Bridge"
Cohesion: 0.07
Nodes (11): Cocoa, Flutter, FlutterMacOS, AppDelegate, SceneDelegate, RunnerTests, AppDelegate, MainFlutterWindow (+3 more)

### Community 11 - "Crossclimb Screen & Ladder Tiles"
Cohesion: 0.06
Nodes (31): build, _buildActiveLadderTile, _buildLadderConnector, _buildRuleCard, _buildStepTile, _buildWordTile, createState, _currentInputChar (+23 more)

### Community 12 - "Zip Path Screen & Wall Grid"
Cohesion: 0.05
Nodes (40): build, _buildRuleCard, cellSize, _checkState, createState, didChangeAppLifecycleState, dispose, edgeWalls (+32 more)

### Community 13 - "Game Stats & IQ Milestone Service"
Cohesion: 0.03
Nodes (57): all, artType, bestDurationMs, bestScore, betterThanPercent, copyWith, _createInitialState, credibility (+49 more)

### Community 14 - "Home Screen Hub & Nav Providers"
Cohesion: 0.05
Nodes (28): GamePerformanceData, _activeLevelId, _checkAppUpdate, color, createState, dateId, game, _GeniusGameButton (+20 more)

### Community 15 - "Pinpoint Screen & Clue Guessing"
Cohesion: 0.06
Nodes (27): build, _buildClueItem, _buildRuleCard, _clueBadgeColors, createState, _currentInputText, didChangeAppLifecycleState, dispose (+19 more)

### Community 16 - "Tango Board Models & Rules"
Cohesion: 0.07
Nodes (26): c1, c2, col, constraints, ConstraintType, difficulty, filledCount, finalGrid (+18 more)

### Community 17 - "Patches Shape Models & Rectangles"
Cohesion: 0.07
Nodes (28): area, bottomRow, clues, col, colorIndex, contains, difficulty, fromPoints (+20 more)

### Community 18 - "Network Checker & Connectivity Guard"
Cohesion: 0.11
Nodes (16): advanceDay, _clockDriftSeconds, controller, _dayOffset, emit, formatCountdown, getTimeUntilNextReset, getTodayDateId (+8 more)

### Community 19 - "Queens Board Models & Regions"
Cohesion: 0.07
Nodes (27): CellBorders, CellContent, col, color, compute, content, copyWith, description (+19 more)

### Community 20 - "win32_window.cpp"
Cohesion: 0.16
Nodes (5): EnableFullDpiSupportIfAvailable(), Win32Window, child_content_, quit_on_close_, window_handle_

### Community 21 - "Linux Desktop Runner & Engine"
Cohesion: 0.10
Nodes (13): main(), first_frame_cb(), my_application_activate(), my_application_class_init(), my_application_dispose(), my_application_init(), my_application_local_command_line(), my_application_new() (+5 more)

### Community 22 - "home_brain_hero_card.dart"
Cohesion: 0.04
Nodes (46): activeDateKey, ambientAnimation, _ambientController, build, _buildWobblyBarPath, _buildWobblyCircle, createState, currentStreak (+38 more)

### Community 23 - "sketch_badge_icons.dart"
Cohesion: 0.04
Nodes (51): accentColor, build, _buildWobblySeal, color, _drawDashedPath, _drawFivePointStar, _drawMiniSpark, isDark (+43 more)

### Community 24 - "Zip Path Grid & Difficulty Models"
Cohesion: 0.09
Nodes (20): col, difficulty, edgeWalls, fromJson, gridSize, hashCode, id, numberPoints (+12 more)

### Community 25 - "Sketch Decorations & Queens Screen"
Cohesion: 0.06
Nodes (30): SketchBadgeMedallion, HandDrawnBadge, HandDrawnCheckBadge, SketchCircularDoodle, SketchDoodleBolt, SketchDoodleBrain, SketchDoodleClipboard, SketchDoodleCrown (+22 more)

### Community 26 - "Home Screen & Zip Screen"
Cohesion: 0.07
Nodes (28): _DoodleLockPainter, _DoodleBoltPainter, _DoodleBrainPainter, _DoodleClipboardPainter, _DoodleCrownPainter, _DoodleFlamePainter, _DoodleHourglassPainter, _DoodleMedalPainter (+20 more)

### Community 27 - "package:daily_games/games/common/base_game.dart"
Cohesion: 0.11
Nodes (13): main, main, main, main, main, debugState, main, main (+5 more)

### Community 28 - "Daily Play Service Module"
Cohesion: 0.07
Nodes (28): completedAt, copyWith, DailyPlayRecord, dateId, durationMs, exportBackupMap, _formatDateKey, fromJson (+20 more)

### Community 29 - "game_logic_test.dart"
Cohesion: 0.07
Nodes (12): main, main, _dateId, main, main, main, main, day (+4 more)

### Community 30 - "genius_win_dialog.dart"
Cohesion: 0.07
Nodes (25): GameStatsUpdateResult, badgeColor, build, _buildAnimatedIQMilestoneCard, createState, fillColor, gameTitle, icon (+17 more)

### Community 31 - "Win32 Window & Flutter Window"
Cohesion: 0.11
Nodes (4): FlutterWindow, flutter_controller_, FlutterWindow::FlutterWindow(), project_

### Community 32 - "Ilerleme & Pubspec"
Cohesion: 0.14
Nodes (17): Realistic IQ Index & Gaussian Distribution, Duolingo Style Weekly League System, Steam Style Badge & Championship Belt Room, flutter_riverpod dependency, shared_preferences dependency, Crossclimb (Kelime Tırmanışı), Patches (Alan Bölme), Pinpoint (Kelime İzleri) (+9 more)

### Community 33 - "package:daily_games/games/common/base_game.dart"
Cohesion: 0.14
Nodes (3): main, main, main

### Community 34 - "pinpoint_levels.dart"
Cohesion: 0.12
Nodes (11): _cache, CrossclimbLevelRepository, getDaily, getLevelForDate, _presets, _cache, getDaily, getLevelForDate (+3 more)

### Community 35 - "queens_lobby_screen.dart"
Cohesion: 0.11
Nodes (12): _activeLeaderboardTab, _buildDifficultyCard, _buildDifficultyLogo, _buildRuleItem, createState, _getDiffColor, _getGridSize, initState (+4 more)

### Community 36 - "Win32 Window Module"
Cohesion: 0.13
Nodes (8): Scale(), Size, height, width, Win32Window::Win32Window(), WindowClassRegistrar, class_registered_, instance_

### Community 37 - "package:flutter/material.dart"
Cohesion: 0.06
Nodes (28): AppTheme, build, createState, icon, isFullWidth, _isPressed, isPrimary, onPressed (+20 more)

### Community 38 - "Player"
Cohesion: 0.20
Nodes (4): AuthController, {closure#1}(), Player, {closure#1}()

### Community 39 - "Profile Screen Module"
Cohesion: 0.08
Nodes (16): color, _DoodleCrossclimbPainter, _DoodleTangoPainter, _DoodleZipPathPainter, fillColor, game, GameSketchThumbnail, icon (+8 more)

### Community 40 - "leaderboard_screen.dart"
Cohesion: 0.07
Nodes (23): _buildEntryCard, _buildQueensDifficultyChip, _buildSeparator, createState, crownWidget, entry, fillColor, initState (+15 more)

### Community 41 - "Patches Models & Patches Logic"
Cohesion: 0.12
Nodes (16): _backtrack, clue, _ClueCandidates, countSolutions, _findCandidatesForClue, getClueCountInRect, hasOverlap, isValidRect (+8 more)

### Community 42 - "daily_genius_certificate_dialog.dart"
Cohesion: 0.09
Nodes (20): build, _CertificateMetricCard, _certKey, createState, dailyPlayState, darkBgColor, dateId, isDark (+12 more)

### Community 44 - "crossclimb_models.dart"
Cohesion: 0.18
Nodes (10): changedIndex, clue, CrossclimbLevel, CrossclimbStep, endWord, id, index, startWord (+2 more)

### Community 45 - "retention_notification_service.dart"
Cohesion: 0.07
Nodes (27): buildStreakNotificationContent, _cancelNative, _channel, computeNextStreakTriggerTime, computeNextSundayReportTriggerTime, copyWith, dailyNotificationHour, ensureLoaded (+19 more)

### Community 46 - "queens_logic.dart"
Cohesion: 0.18
Nodes (10): autoCrossNeighbors, DeductiveResult, isSolvable, QueensLogic, solution, _solve2QueensBacktracking, solveBacktracking, solveDeductively (+2 more)

### Community 47 - "leaderboard_service.dart"
Cohesion: 0.06
Nodes (26): apiClient, _buildCacheKey, enableMockBots, _excess, getLeaderboard, hasServerDataFor, _initServerSync, isServerConnected (+18 more)

### Community 48 - "App Spacing Module"
Cohesion: 0.14
Nodes (12): AppSpacing, borderRadiusLg, borderRadiusMd, borderRadiusSm, borderRadiusXl, lg, md, sm (+4 more)

### Community 49 - "Patches Levels Module"
Cohesion: 0.14
Nodes (11): _cache, _epoch, getDaily, getDifficultyForDate, getDifficultyForDays, getLevelForDate, getLevelForDateAndDifficulty, PatchesDifficultyScheduler (+3 more)

### Community 50 - "_"
Cohesion: 0.12
Nodes (15): _, _areAllRegionsConnected, canonical, _connectPair, fingerprint, generate, _growRegions, _growRegionsFromPairs (+7 more)

### Community 51 - "Main & Utils"
Cohesion: 0.19
Nodes (4): wWinMain(), CreateAndAttachConsole(), GetCommandLineArguments(), Utf8FromUtf16()

### Community 53 - "Tango Levels Module"
Cohesion: 0.15
Nodes (11): _cache, _epoch, getDaily, getDifficultyForDate, getDifficultyForDays, getLevelForDate, getLevelForDateAndDifficulty, _pick (+3 more)

### Community 54 - "Zip Levels Module"
Cohesion: 0.15
Nodes (11): _cache, _epoch, getDaily, getDifficultyForDate, getDifficultyForDays, getLevelForDate, getLevelForDateAndDifficulty, _pick (+3 more)

### Community 55 - "date_utils.dart"
Cohesion: 0.09
Nodes (17): advanceToNextDay, _clockDriftSeconds, _customDate, _dayOffset, formatCountdown, formatGameTime, GameDateUtils, getActiveDate (+9 more)

### Community 56 - "Queens Levels Module"
Cohesion: 0.17
Nodes (10): _cache, _epoch, getDaily, getDifficultyForDate, getDifficultyForDays, getLevelForDate, getLevelForDateAndDifficulty, _pick (+2 more)

### Community 57 - "settings_screen.dart"
Cohesion: 0.08
Nodes (19): accentColor, _buildSectionHeader, _checkUpdate, createState, icon, initState, _isChecking, isSelected (+11 more)

### Community 59 - "theme_service.dart"
Cohesion: 0.25
Nodes (5): currentMode, _loadFromPrefs, _prefKey, setThemeMode, toggleTheme

### Community 60 - "Patches Generator Module"
Cohesion: 0.18
Nodes (9): _, area, generate, _generateTiling, h, maxAttempts, PatchesGenerator, _RectDim (+1 more)

### Community 61 - "sound_haptic_service.dart"
Cohesion: 0.07
Nodes (26): _channel, copyWith, ensureLoaded, hapticEnabled, _hapticPrefKey, _init, instance, _lastTapTime (+18 more)

### Community 63 - "package:flutter_riverpod/flutter_riverpod.dart"
Cohesion: 0.14
Nodes (3): main, main, main

### Community 64 - "MainActivity.kt"
Cohesion: 0.06
Nodes (13): MainActivity, ToneStep, RetentionNotificationReceiver, background_color, description, display, icons, name (+5 more)

### Community 65 - "State"
Cohesion: 0.16
Nodes (14): AppButton, _AppButtonState, AppCard, _AppCardState, GeniusWinDialog, _GeniusWinDialogState, DailyGeniusCertificateDialog, _DailyGeniusCertificateDialogState (+6 more)

### Community 66 - "Tango Logic Module"
Cohesion: 0.20
Nodes (8): countSolutions, findConflicts, _hasIdenticalLines, isPlacementValid, solve, solveDeductively, TangoLogic, validateGrid

### Community 67 - "_"
Cohesion: 0.20
Nodes (8): _, _chain, CrossclimbGenerator, _cycleOrders, _epoch, generate, _orderForCycle, pool

### Community 68 - "completed_game_leaderboard_dialog.dart"
Cohesion: 0.14
Nodes (8): createState, difficulty, durationMs, game, levelId, score, subtitle, title

### Community 69 - "time_machine_dialog.dart"
Cohesion: 0.12
Nodes (14): activeLevelId, build, _buildMonthCalendar, createState, _currentMonth, dailyPlayState, _formatLevelId, _getMonthName (+6 more)

### Community 70 - "admin.js"
Cohesion: 0.21
Nodes (34): apiFetch(), buildMonthOptions(), countDiff(), escapeHtml(), findEntry(), formatDateTr(), loadCalendar(), normTr() (+26 more)

### Community 71 - "../../games/common/base_game.dart"
Cohesion: 0.20
Nodes (8): clearSession, GameSessionService, gameSessionServiceProvider, loadSession, _makeKey, _prefix, saveSession, updateElapsedMs

### Community 72 - "user_avatar_provider.dart"
Cohesion: 0.13
Nodes (12): UserAvatar, ApiClient, apiClient, _avatarKey, getById, id, _loadInitialAvatar, setAvatar (+4 more)

### Community 73 - "Illuminate\Database\Schema\Blueprint"
Cohesion: 0.07
Nodes (16): {closure#1}(), {closure#2}(), {closure#3}(), {closure#1}(), {closure#2}(), {closure#1}(), {closure#2}(), {closure#3}() (+8 more)

### Community 74 - "update_prompt_dialog.dart"
Cohesion: 0.06
Nodes (30): AppUpdateInfo, bgColor, build, _buildActionButtons, _buildDownloadingView, _buildErrorView, _buildInstallingView, createState (+22 more)

### Community 76 - "badges_screen.dart"
Cohesion: 0.09
Nodes (17): _BadgesSketchProgressBarPainter, _buildBadgeCard, _buildCategoryChip, createState, fillColor, initialCategory, initState, _onlyUnlocked (+9 more)

### Community 77 - "user_avatar.dart"
Cohesion: 0.11
Nodes (16): accentColor, allAvatars, AvatarBgColorOption, bgColorOptions, buildWidget, color, colorId, copyWith (+8 more)

### Community 78 - "update_service.dart"
Cohesion: 0.06
Nodes (28): apkUrl, changelog, checkForUpdate, compareSemver, currentBuildNumber, currentVersion, _dismissedBuildNumberInSession, dismissThisSession (+20 more)

### Community 79 - "dailyPlayServiceProvider"
Cohesion: 0.13
Nodes (34): badgeServiceProvider, dailyPlayServiceProvider, gameStatsServiceProvider, _init, toggleStreakReminder, toggleSundayReport, _checkSundayWeeklyReport, _openTimeMachine (+26 more)

### Community 80 - "api_client.dart"
Cohesion: 0.06
Nodes (33): _authToken, _authTokenKey, _cachedBaseUrl, _cachedNickname, _cachedRecoveryCode, checkConnectionAndTimeSync, checkNicknameAvailability, _client (+25 more)

### Community 81 - "remote_puzzle_store.dart"
Cohesion: 0.06
Nodes (29): _crossclimbCache, DaySpecialMeta, _gamePayload, getCrossclimb, getPatches, getPinpoint, getQueens, getSpecialMeta (+21 more)

### Community 82 - "List"
Cohesion: 0.25
Nodes (6): alternativeAnswers, categoryHint, clues, id, PinpointLevel, targetWord

### Community 83 - "cloud_backup_service.dart"
Cohesion: 0.12
Nodes (12): _backupSignatureSalt, copyWith, decodePortableBackupKey, deriveDeterministicCodeFromDeviceId, exportPortableBackupKey, isSyncing, lastMessage, lastSyncedAt (+4 more)

### Community 84 - "ConsumerState"
Cohesion: 0.16
Nodes (16): _GeniusLobbyTab, _GeniusLobbyTabState, HomeScreen, _HomeScreenState, LeaderboardScreen, _LeaderboardScreenState, CompletedGameLeaderboardDialog, _CompletedGameLeaderboardDialogState (+8 more)

### Community 86 - "base_game.dart"
Cohesion: 0.09
Nodes (22): GameCognitiveDomainExt, avatarId, bestTimeMs, completedAt, difficulty, durationMs, fromJson, GameResult (+14 more)

### Community 89 - "package.json"
Cohesion: 0.10
Nodes (20): concurrently, @laravel/multiplex, laravel-vite-plugin, tailwindcss, @tailwindcss/vite, vite, devDependencies, concurrently (+12 more)

### Community 92 - "require"
Cohesion: 0.33
Nodes (5): require, laravel/framework, laravel/sanctum, laravel/tinker, php

### Community 93 - "ApiTest"
Cohesion: 0.15
Nodes (4): ApiTest, DailyPuzzleApiTest, ExampleTest, TestCase

### Community 104 - "player_server_stats.dart"
Cohesion: 0.12
Nodes (15): allTimeScore, avgDurationMs, bestScore, bestTimeMs, fromJson, games, GameServerStats, gamesPlayed (+7 more)

### Community 105 - "backup_restore_dialog.dart"
Cohesion: 0.13
Nodes (15): cloudBackupProvider, BackupRestoreDialog, _BackupRestoreDialogState, build, createState, dispose, _feedbackMessage, _formatLastSync (+7 more)

### Community 106 - "composer.json"
Cohesion: 0.22
Nodes (8): description, keywords, license, minimum-stability, name, prefer-stable, $schema, type

### Community 107 - "scripts"
Cohesion: 0.22
Nodes (9): scripts, dev, post-autoload-dump, post-create-project-cmd, post-root-package-install, post-update-cmd, pre-package-uninstall, setup (+1 more)

### Community 108 - "require-dev"
Cohesion: 0.25
Nodes (8): require-dev, fakerphp/faker, laravel/pail, laravel/pao, laravel/pint, mockery/mockery, nunomaduro/collision, phpunit/phpunit

### Community 109 - "README.md"
Cohesion: 0.25
Nodes (7): About Laravel, Agentic Development, Code of Conduct, Contributing, Learning Laravel, License, Security Vulnerabilities

### Community 110 - "queens_board_painter.dart"
Cohesion: 0.17
Nodes (10): _drawHandDrawnOuterFrame, _drawOrganicLine, grid, gridSize, isDark, paint, palette, QueensBoardPainter (+2 more)

### Community 111 - "config"
Cohesion: 0.29
Nodes (7): pestphp/pest-plugin, php-http/discovery, config, allow-plugins, optimize-autoloader, preferred-install, sort-packages

### Community 112 - "_"
Cohesion: 0.13
Nodes (11): _, _createDeterministicFallback, generate, _generateEdgeWalls, _generateHamiltonianPath, maxAttempts, _placeCheckpoints, ZipGenerator (+3 more)

### Community 114 - "weekly_brain_report_dialog.dart"
Cohesion: 0.05
Nodes (43): barColor, _buildShareText, _buildWobblyBarPath, calculate, _CognitiveDomainBar, cognitiveFocusPercent, customIcon, darkBgColor (+35 more)

### Community 115 - "game_card_logos.dart"
Cohesion: 0.11
Nodes (17): animate, build, _drawDoodlePuffCloud, _drawDoodleQuestion, _drawFreehandSparkle, GameBackgroundLogo, gameType, _getPainter (+9 more)

### Community 118 - "psr-4"
Cohesion: 0.40
Nodes (5): autoload, psr-4, App\\, Database\\Factories\\, Database\\Seeders\\

### Community 120 - "nickname_prompt_dialog.dart"
Cohesion: 0.22
Nodes (7): build, _controller, createState, dispose, _errorMessage, isEditing, _isLoading

### Community 122 - "Laravel Application"
Cohesion: 0.50
Nodes (3): Agent Setup, Laravel Application, Prerequisites

### Community 123 - "Laravel Application"
Cohesion: 0.50
Nodes (3): Agent Setup, Laravel Application, Prerequisites

### Community 125 - "autoload-dev"
Cohesion: 0.67
Nodes (3): autoload-dev, psr-4, Tests\\

### Community 126 - "extra"
Cohesion: 0.67
Nodes (3): extra, laravel, dont-discover

### Community 134 - "leagueServiceProvider"
Cohesion: 0.16
Nodes (19): networkCheckerProvider, leagueServiceProvider, playerStatsServiceProvider, currentAvatarModelProvider, build, OnlineGuardWidget, homeBottomNavIndexProvider, WeeklyBrainReportDialog (+11 more)

### Community 135 - "head_to_head_share_dialog.dart"
Cohesion: 0.07
Nodes (27): _buildMetricPill, _buildShareText, _cardKey, createState, dateId, dateString, difficulty, _drawPostmarkStamp (+19 more)

### Community 136 - "userNicknameProvider"
Cohesion: 0.16
Nodes (14): apiClientProvider, applyProgressPayload, buildProgressPayload, CloudBackupNotifier, CloudBackupState, _init, userNicknameProvider, initState (+6 more)

### Community 137 - "player_stats_service.dart"
Cohesion: 0.17
Nodes (8): apiClient, initialize, _isRefreshing, _loadFromLocal, notifier, _prefKey, refreshStats, userNickname

### Community 138 - "badge_service.dart"
Cohesion: 0.12
Nodes (12): awardBadge, evaluateBadges, exportBackupMap, _findDef, isUnlocked, _loadBadges, _prefKey, remainingDays (+4 more)

### Community 139 - "../theme/app_colors.dart"
Cohesion: 0.20
Nodes (7): nextResetCountdownProvider, timeSyncServiceProvider, build, fontSize, padding, showLabel, SketchCountdownTimer

### Community 141 - "daily_social_share_dialog.dart"
Cohesion: 0.07
Nodes (25): _buildMiniGamePill, _buildShareText, _cardKey, createState, dailyPlayState, DailySocialShareDialog, _DailySocialShareDialogState, dateId (+17 more)

### Community 142 - "app_text_styles.dart"
Cohesion: 0.14
Nodes (13): AppTextStyles, bodyLarge, bodyMedium, bodySmall, cleanSans, displayLarge, headlineLarge, headlineMedium (+5 more)

### Community 143 - "dart:async"
Cohesion: 0.18
Nodes (5): _connectivity, dispose, _init, _subscription, _updateState

### Community 144 - "onboarding_screen.dart"
Cohesion: 0.06
Nodes (30): build, _buildMiniGamePill, _buildOverflowingBadgesCup, _buildSlide1, _buildSlide2, _buildSlide3, _buildSlide4, _buildSlide5 (+22 more)

### Community 145 - "Map"
Cohesion: 0.20
Nodes (8): PlayerServerStats, NetworkCheckerNotifier, LeagueNotifier, LeagueState, PlayerStatsNotifier, ThemeNotifier, UserAvatarNotifier, UserNicknameNotifier

### Community 146 - "puzzle_serializer.dart"
Cohesion: 0.09
Nodes (15): crossclimbFromJson, crossclimbToJson, _parseSymbol, patchesFromJson, patchesToJson, pinpointFromJson, pinpointToJson, PuzzleSerializer (+7 more)

### Community 147 - "onboarding_and_share_test.dart"
Cohesion: 0.12
Nodes (4): SketchCard, SketchPlaceholderBox, main, main

### Community 148 - "sketch_league_emblems.dart"
Cohesion: 0.08
Nodes (24): build, _buildFourPointStar, _buildHeraldicCrestPath, isDark, isLocked, level, paint, _paintBronzeGladiatorCrest (+16 more)

### Community 149 - "Zühtü Zeka Oyunları - Gizlilik Politikası (Privacy Policy)"
Cohesion: 0.25
Nodes (7): 1. Toplanan Veriler ve Kullanım Amaçları, 2. Verilerin Saklanması ve Güvenliği, 3. İzinler ve Bildirimler, 4. Hesap ve Veri Silme Hakkı (Google Play Data Safety), 5. Çocukların Gizliliği, 6. İletişim, Zühtü Zeka Oyunları - Gizlilik Politikası (Privacy Policy)

### Community 150 - "Point"
Cohesion: 0.50
Nodes (3): Point, x, y

### Community 151 - "share_card_helper.dart"
Cohesion: 0.15
Nodes (6): captureWidgetToFile, captureWidgetToPngBytes, lastError, shareCard, ShareCardHelper, _waitForPaintFrame

### Community 152 - "_"
Cohesion: 0.25
Nodes (5): _, _epoch, generate, PinpointGenerator, pool

### Community 154 - "GameScore"
Cohesion: 0.17
Nodes (4): GameController, LeaderboardController, Controller, GameScore

### Community 155 - "SettingsScreen"
Cohesion: 0.16
Nodes (13): retentionNotificationProvider, soundHapticProvider, themeServiceProvider, build, _checkOnboarding, initState, _launchGame, build (+5 more)

### Community 157 - "dart:math"
Cohesion: 0.22
Nodes (7): _, derive, devSecret, fingerprint, PuzzleSeed, random, toInt

### Community 158 - "Illuminate\Http\Request"
Cohesion: 0.33
Nodes (3): AdminPuzzleController, PuzzleController, DailyPuzzle

### Community 159 - "_"
Cohesion: 0.29
Nodes (6): _, calculateScore, isCorrectGuess, normalize, PinpointLogic, validateLevel

### Community 161 - "🚀 Daily Games (Zühtü) - Devir Teslim & VPS Geçiş Kılavuzu"
Cohesion: 0.15
Nodes (9): DatabaseSeeder, RealisticBotSeeder, 📌 1. Projenin Genel Durumu ve Yapılanlar, 🎯 2. Kullanıcının Hedefi ve Vizyonu, 🛠️ 3. Evdeki Bilgisayarda İlk Yapılacaklar (Git & Başlangıç), 🌐 4. Canlı VPS Sunucu Durumu (AKTİF & ÇALIŞIYOR), 📋 5. Sırada Bekleyen Diğer Geliştirme Maddeleri (`oyun_hatalari.md`), 🚀 Daily Games (Zühtü) - Devir Teslim & VPS Geçiş Kılavuzu (+1 more)

### Community 162 - "_"
Cohesion: 0.22
Nodes (7): _, _extractPotentialConstraints, generate, _generateFullSolution, maxAttempts, _rowMatchesAnyPrevious, TangoGenerator

### Community 163 - "userAvatarProvider"
Cohesion: 0.40
Nodes (5): userAvatarProvider, build, build, build, initState

### Community 164 - "_"
Cohesion: 0.22
Nodes (8): _, calculateScore, CrossclimbLogic, findChangedIndex, hammingDistance, isStepValid, normalize, validateLevel

### Community 165 - "Map"
Cohesion: 0.50
Nodes (3): BadgeNotifier, GameStatsNotifier, GameStatsNotifierTestExt

### Community 167 - "PuzzleRepository"
Cohesion: 0.22
Nodes (8): getDaily, PuzzleRepository, LocalCrossclimbPuzzleRepository, LocalPatchesPuzzleRepository, LocalPinpointPuzzleRepository, LocalQueensPuzzleRepository, LocalTangoPuzzleRepository, LocalZipPuzzleRepository

### Community 168 - "bootstrap/app.php"
Cohesion: 0.32
Nodes (3): {closure#1}(), {closure#2}(), {closure#3}()

### Community 170 - "admin/auth.php"
Cohesion: 0.57
Nodes (6): getAdminCsrfToken(), isAdminLoggedIn(), loadAdminConfig(), logoutAdmin(), startAdminSession(), verifyAdminLogin()

### Community 173 - "DailyPlayState"
Cohesion: 0.67
Nodes (3): DailyPlayNotifier, DailyPlayState, DailyPlayNotifierTestExt

## Knowledge Gaps
- **1746 isolated node(s):** `DailyBadge`, `UserBadge`, `label`, `subtitle`, `id` (+1741 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 2157 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **45 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `_` connect `_` to `_`, `pinpoint_levels.dart`, `_`, `_`?**
  _High betweenness centrality (0.018) - this node is a cross-community bridge._
- **Are the 37 inferred relationships involving `Kara Kalem Eskiz Defteri Design Language` (e.g. with `mipmap-hdpi/ic_launcher.png` and `mipmap-mdpi/ic_launcher.png`) actually correct?**
  _`Kara Kalem Eskiz Defteri Design Language` has 37 INFERRED edges - model-reasoned connections that need verification._
- **What connects `DailyBadge`, `UserBadge`, `label` to the rest of the system?**
  _1746 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Color Theme & Palette Tokens` be split into smaller, more focused modules?**
  _Cohesion score 0.02247191011235955 - nodes in this community are weakly interconnected._
- **Why does `Win32Window` connect `win32_window.cpp` to `string`, `Win32 Window Module`, `Point`, `Win32 Window & Flutter Window`?**
  _High betweenness centrality (0.018) - this node is a cross-community bridge._
- **Should `Queens Screen & Solver UI` be split into smaller, more focused modules?**
  _Cohesion score 0.02531645569620253 - nodes in this community are weakly interconnected._
- **Why does `_` connect `dart:math` to `theme_service.dart`, `package:daily_games/games/common/base_game.dart`?**
  _High betweenness centrality (0.010) - this node is a cross-community bridge._