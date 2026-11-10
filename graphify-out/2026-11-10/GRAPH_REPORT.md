# Graph Report - daily  (2026-11-10)

## Corpus Check
- 195 files · ~166,645 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 74 file(s) not represented in the graph (top: (none) 24, .xml 9, .xcconfig 8)

## Summary
- 2717 nodes · 3996 edges · 149 communities (111 shown, 38 thin omitted)
- Extraction: 98% EXTRACTED · 2% INFERRED · 0% AMBIGUOUS · INFERRED: 73 edges (avg confidence: 0.78)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `82c8be1e`
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
- package:shared_preferences/shared_preferences.dart
- Daily Play Service Module
- game_logic_test.dart
- genius_win_dialog.dart
- Win32 Window & Flutter Window
- Ilerleme & Pubspec
- package:flutter_riverpod/flutter_riverpod.dart
- Crossclimb Levels & Pinpoint Levels
- queens_lobby_screen.dart
- Win32 Window Module
- package:google_fonts/google_fonts.dart
- Player
- Profile Screen Module
- leaderboard_screen.dart
- Patches Models & Patches Logic
- daily_genius_certificate_dialog.dart
- package:flutter/services.dart
- Crossclimb Generator & Pinpoint Generator
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
- _launchGame
- ../../core/widgets/sketch_decorations.dart
- Patches Generator Module
- sound_haptic_service.dart
- past_game_score_and_iq_test.dart
- Crossclimb Models Module
- MainActivity.kt
- State
- Tango Logic Module
- Crossclimb Logic Module
- completed_game_leaderboard_dialog.dart
- time_machine_dialog.dart
- Puzzle Repository & Zip Levels
- _
- queens_counting_and_badges_test.dart
- Illuminate\Database\Schema\Blueprint
- update_prompt_dialog.dart
- package:flutter_test/flutter_test.dart
- badges_screen.dart
- Pinpoint Logic Module
- update_service.dart
- dailyPlayServiceProvider
- api_client.dart
- pinpoint_test.dart
- Win32 Window Module
- cloud_backup_service.dart
- ConsumerStatefulWidget
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
- crossclimb_test.dart
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
- userNicknameProvider
- head_to_head_share_dialog.dart
- leagueServiceProvider
- player_stats_service.dart
- badge_service.dart
- main.dart
- dart:math
- dart:convert
- dart:async
- _
- Map
- zip_logic.dart
- time_machine_test.dart
- List

## God Nodes (most connected - your core abstractions)
1. `Kara Kalem Eskiz Defteri Design Language` - 37 edges
2. `dailyPlayServiceProvider` - 31 edges
3. `leaderboardServiceProvider` - 24 edges
4. `gameStatsServiceProvider` - 23 edges
5. `Player` - 23 edges
6. `badgeServiceProvider` - 21 edges
7. `Win32Window` - 21 edges
8. `_` - 19 edges
9. `_` - 16 edges
10. `leagueServiceProvider` - 15 edges

## Surprising Connections (you probably didn't know these)
- `📌 1. Projenin Genel Durumu ve Yapılanlar` --references--> `GameScore`  [INFERRED]
  VPS_KURULUMU_VE_DURUM.md → server/app/Models/GameScore.php
- `📌 1. Projenin Genel Durumu ve Yapılanlar` --references--> `Player`  [INFERRED]
  VPS_KURULUMU_VE_DURUM.md → server/app/Models/Player.php
- `🌐 4. Canlı VPS Sunucu Durumu (AKTİF & ÇALIŞIYOR)` --references--> `RealisticBotSeeder`  [INFERRED]
  VPS_KURULUMU_VE_DURUM.md → server/database/seeders/RealisticBotSeeder.php
- `DailyPlayNotifierTestExt` --extends--> `DailyPlayNotifier`  [EXTRACTED]
  test/past_game_score_and_iq_test.dart → lib/core/services/daily_play_service.dart
- `_init` --references--> `dailyPlayServiceProvider`  [EXTRACTED]
  lib/core/services/retention_notification_service.dart → lib/core/services/daily_play_service.dart

## Import Cycles
- None detected.

## Hyperedges (group relationships)
- **The 6 Daily Puzzle Games** — readme_game_queens, readme_game_tango, readme_game_zip, readme_game_pinpoint, readme_game_crossclimb, readme_game_patches [EXTRACTED 1.00]
- **Zühtü Gamification & Motivation Architecture** — ilerleme_league_system, ilerleme_iq_index_system, ilerleme_steam_badge_system, rozetler_championship_belts, rozetler_streak_badges [INFERRED 0.95]

## Communities (149 total, 38 thin omitted)

### Community 0 - "Color Theme & Palette Tokens"
Cohesion: 0.02
Nodes (85): accentAmber, accentCyan, accentGreen, accentOrange, accentPink, accentPurple, adaptive, AppColors (+77 more)

### Community 1 - "Queens Screen & Solver UI"
Cohesion: 0.03
Nodes (72): activeColor, _activeHintIsWarning, _activeHintMessage, _activeHintTitle, _applyDragToCell, build, _buildCellContent, _buildHintInfoCard (+64 more)

### Community 2 - "Sketch Paper & Notebook Theme"
Cohesion: 0.04
Nodes (50): backgroundColor, borderColor, borderRadius, borderWidth, build, _buildOrganicPath, _buildWobblyPath, centerChild (+42 more)

### Community 3 - "badge_model.dart"
Cohesion: 0.08
Nodes (23): allBadges, artType, badgeId, _buildStreakBadges, category, color, DailyBadge, description (+15 more)

### Community 4 - "Weekly League & Bot Engine"
Cohesion: 0.04
Nodes (55): _allBotNames, apiClient, _buildLeaguePlayers, _calculateUserScoreForWeek, _calculateUserWeeklyScore, checkWeekTransition, clearPendingLeagueChange, copyWith (+47 more)

### Community 5 - "Patches Screen & Grid Division"
Cohesion: 0.05
Nodes (39): build, _buildRuleCard, _buildShapeMiniIcon, _cellFromOffset, _checkState, color, createState, didChangeAppLifecycleState (+31 more)

### Community 6 - "Core Sketch Controls & Win Dialog"
Cohesion: 0.08
Nodes (23): _animController, build, child, color, _ConfettiPainter, _ConfettiParticle, _controller, createState (+15 more)

### Community 7 - "Tango Screen & Grid Controls"
Cohesion: 0.05
Nodes (38): build, _buildRuleCard, _buildSymbol, c, _cachedSolution, _checkState, _conflictDebounceTimer, createState (+30 more)

### Community 9 - "League Promotion Ladder UI"
Cohesion: 0.05
Nodes (37): LeaguePlayer, _animController, _avatarEmoji, backgroundColor, barBackgroundColor, build, _buildRankWidget, _buildWobblyRect (+29 more)

### Community 10 - "iOS Runner & Engine Bridge"
Cohesion: 0.07
Nodes (11): Cocoa, Flutter, FlutterMacOS, AppDelegate, SceneDelegate, RunnerTests, AppDelegate, MainFlutterWindow (+3 more)

### Community 11 - "Crossclimb Screen & Ladder Tiles"
Cohesion: 0.06
Nodes (31): build, _buildActiveLadderTile, _buildLadderConnector, _buildRuleCard, _buildStepTile, _buildWordTile, createState, _currentInputChar (+23 more)

### Community 12 - "Zip Path Screen & Wall Grid"
Cohesion: 0.06
Nodes (33): build, _buildRuleCard, cellSize, _checkState, createState, didChangeAppLifecycleState, dispose, edgeWalls (+25 more)

### Community 13 - "Game Stats & IQ Milestone Service"
Cohesion: 0.03
Nodes (57): all, artType, bestDurationMs, bestScore, betterThanPercent, copyWith, _createInitialState, credibility (+49 more)

### Community 14 - "Home Screen Hub & Nav Providers"
Cohesion: 0.05
Nodes (26): GamePerformanceData, _activeLevelId, _checkAppUpdate, color, createState, dateId, game, icon (+18 more)

### Community 15 - "Pinpoint Screen & Clue Guessing"
Cohesion: 0.06
Nodes (26): build, _buildClueItem, _buildRuleCard, _clueBadgeColors, createState, _currentInputText, didChangeAppLifecycleState, dispose (+18 more)

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
Nodes (49): accentColor, build, _buildWobblySeal, color, _drawDashedPath, _drawFivePointStar, _drawMiniSpark, isDark (+41 more)

### Community 24 - "Zip Path Grid & Difficulty Models"
Cohesion: 0.09
Nodes (20): col, difficulty, edgeWalls, fromJson, gridSize, hashCode, id, numberPoints (+12 more)

### Community 25 - "Sketch Decorations & Queens Screen"
Cohesion: 0.06
Nodes (31): SketchBadgeMedallion, HandDrawnBadge, HandDrawnCheckBadge, SketchCard, SketchCircularDoodle, SketchDoodleBrain, SketchDoodleCrown, SketchDoodleFlame (+23 more)

### Community 26 - "Home Screen & Zip Screen"
Cohesion: 0.06
Nodes (30): _DoodleLockPainter, _SketchBadgeArtPainter, _WobblyBadgeMedallionPainter, _DoodleBrainPainter, _DoodleCrownPainter, _DoodleFlamePainter, _DoodleTrophyPainter, _HandDrawnBadgePainter (+22 more)

### Community 27 - "package:shared_preferences/shared_preferences.dart"
Cohesion: 0.13
Nodes (9): main, main, main, main, main, main, main, main (+1 more)

### Community 28 - "Daily Play Service Module"
Cohesion: 0.06
Nodes (31): completedAt, copyWith, DailyPlayNotifier, DailyPlayRecord, DailyPlayState, dateId, durationMs, exportBackupMap (+23 more)

### Community 29 - "game_logic_test.dart"
Cohesion: 0.11
Nodes (5): main, _dateId, main, main, main

### Community 30 - "genius_win_dialog.dart"
Cohesion: 0.07
Nodes (26): badgeColor, build, _buildAnimatedIQMilestoneCard, createState, fillColor, gameTitle, GeniusWinDialog, _GeniusWinDialogState (+18 more)

### Community 31 - "Win32 Window & Flutter Window"
Cohesion: 0.11
Nodes (4): FlutterWindow, flutter_controller_, FlutterWindow::FlutterWindow(), project_

### Community 32 - "Ilerleme & Pubspec"
Cohesion: 0.14
Nodes (17): Realistic IQ Index & Gaussian Distribution, Duolingo Style Weekly League System, Steam Style Badge & Championship Belt Room, flutter_riverpod dependency, shared_preferences dependency, Crossclimb (Kelime Tırmanışı), Patches (Alan Bölme), Pinpoint (Kelime İzleri) (+9 more)

### Community 33 - "package:flutter_riverpod/flutter_riverpod.dart"
Cohesion: 0.09
Nodes (14): clearSession, GameSessionService, gameSessionServiceProvider, loadSession, _makeKey, _prefix, saveSession, updateElapsedMs (+6 more)

### Community 34 - "Crossclimb Levels & Pinpoint Levels"
Cohesion: 0.12
Nodes (11): _cache, CrossclimbLevelRepository, getDaily, getLevelForDate, _presets, _cache, getDaily, getLevelForDate (+3 more)

### Community 35 - "queens_lobby_screen.dart"
Cohesion: 0.10
Nodes (15): _activeLeaderboardTab, build, _buildDifficultyCard, _buildDifficultyLogo, _buildLeaderboardForDifficulty, _buildRuleItem, createState, _fetchCurrentLeaderboard (+7 more)

### Community 36 - "Win32 Window Module"
Cohesion: 0.13
Nodes (8): Scale(), Size, height, width, Win32Window::Win32Window(), WindowClassRegistrar, class_registered_, instance_

### Community 37 - "package:google_fonts/google_fonts.dart"
Cohesion: 0.12
Nodes (12): AppTextStyles, bodyLarge, bodyMedium, displayLarge, headlineLarge, headlineMedium, labelLarge, titleLarge (+4 more)

### Community 38 - "Player"
Cohesion: 0.06
Nodes (20): AuthController, GameController, LeaderboardController, Controller, GameScore, {closure#1}(), Player, {closure#1}() (+12 more)

### Community 39 - "Profile Screen Module"
Cohesion: 0.06
Nodes (19): accentColor, _checkUpdate, createState, currentStreak, fillColor, icon, initState, _isChecking (+11 more)

### Community 40 - "leaderboard_screen.dart"
Cohesion: 0.07
Nodes (23): _buildEntryCard, _buildQueensDifficultyChip, _buildSeparator, createState, crownWidget, entry, fillColor, initState (+15 more)

### Community 41 - "Patches Models & Patches Logic"
Cohesion: 0.12
Nodes (16): _backtrack, clue, _ClueCandidates, countSolutions, _findCandidatesForClue, getClueCountInRect, hasOverlap, isValidRect (+8 more)

### Community 42 - "daily_genius_certificate_dialog.dart"
Cohesion: 0.10
Nodes (18): build, _CertificateMetricCard, DailyGeniusCertificateDialog, dailyPlayState, darkBgColor, dateId, isDark, label (+10 more)

### Community 43 - "package:flutter/services.dart"
Cohesion: 0.07
Nodes (21): AppTheme, build, createState, icon, isFullWidth, _isPressed, isPrimary, onPressed (+13 more)

### Community 44 - "Crossclimb Generator & Pinpoint Generator"
Cohesion: 0.15
Nodes (10): _, CrossclimbGenerator, _epoch, generate, pool, _, _epoch, generate (+2 more)

### Community 45 - "retention_notification_service.dart"
Cohesion: 0.07
Nodes (29): buildStreakNotificationContent, _cancelNative, _channel, computeNextStreakTriggerTime, computeNextSundayReportTriggerTime, copyWith, ensureLoaded, idStreakReminder (+21 more)

### Community 46 - "queens_logic.dart"
Cohesion: 0.17
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
Cohesion: 0.14
Nodes (13): _, canonical, fingerprint, generate, _growRegions, _growRegionsFromPairs, maxAttempts, _pairQueens (+5 more)

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

### Community 57 - "_launchGame"
Cohesion: 0.50
Nodes (3): _launchGame, build, _launchQueens

### Community 58 - "../../core/widgets/sketch_decorations.dart"
Cohesion: 0.10
Nodes (9): child, build, child, gameType, levelId, NeoGameLayout, onRestart, statsBar (+1 more)

### Community 60 - "Patches Generator Module"
Cohesion: 0.18
Nodes (9): _, area, generate, _generateTiling, h, maxAttempts, PatchesGenerator, _RectDim (+1 more)

### Community 61 - "sound_haptic_service.dart"
Cohesion: 0.07
Nodes (26): _channel, copyWith, ensureLoaded, hapticEnabled, _hapticPrefKey, _init, instance, _lastTapTime (+18 more)

### Community 62 - "past_game_score_and_iq_test.dart"
Cohesion: 0.18
Nodes (4): main, debugState, main, main

### Community 63 - "Crossclimb Models Module"
Cohesion: 0.18
Nodes (10): changedIndex, clue, CrossclimbLevel, CrossclimbStep, endWord, id, index, startWord (+2 more)

### Community 64 - "MainActivity.kt"
Cohesion: 0.06
Nodes (13): MainActivity, ToneStep, RetentionNotificationReceiver, background_color, description, display, icons, name (+5 more)

### Community 65 - "State"
Cohesion: 0.16
Nodes (14): AppButton, _AppButtonState, AppCard, _AppCardState, GeniusConfettiOverlay, _GeniusConfettiOverlayState, ScreenShake, ScreenShakeState (+6 more)

### Community 66 - "Tango Logic Module"
Cohesion: 0.20
Nodes (8): countSolutions, findConflicts, _hasIdenticalLines, isPlacementValid, solve, solveDeductively, TangoLogic, validateGrid

### Community 67 - "Crossclimb Logic Module"
Cohesion: 0.22
Nodes (8): _, calculateScore, CrossclimbLogic, findChangedIndex, hammingDistance, isStepValid, normalize, validateLevel

### Community 68 - "completed_game_leaderboard_dialog.dart"
Cohesion: 0.12
Nodes (12): build, CompletedGameLeaderboardDialog, _CompletedGameLeaderboardDialogState, createState, difficulty, durationMs, game, initState (+4 more)

### Community 69 - "time_machine_dialog.dart"
Cohesion: 0.12
Nodes (16): activeLevelId, build, _buildMonthCalendar, createState, _currentMonth, dailyPlayState, _formatLevelId, _getMonthName (+8 more)

### Community 70 - "Puzzle Repository & Zip Levels"
Cohesion: 0.22
Nodes (8): getDaily, PuzzleRepository, LocalCrossclimbPuzzleRepository, LocalPatchesPuzzleRepository, LocalPinpointPuzzleRepository, LocalQueensPuzzleRepository, LocalTangoPuzzleRepository, LocalZipPuzzleRepository

### Community 71 - "_"
Cohesion: 0.22
Nodes (7): _, _extractPotentialConstraints, generate, _generateFullSolution, maxAttempts, _rowMatchesAnyPrevious, TangoGenerator

### Community 73 - "Illuminate\Database\Schema\Blueprint"
Cohesion: 0.08
Nodes (15): {closure#1}(), {closure#2}(), {closure#3}(), {closure#1}(), {closure#2}(), {closure#1}(), {closure#2}(), {closure#3}() (+7 more)

### Community 74 - "update_prompt_dialog.dart"
Cohesion: 0.06
Nodes (29): bgColor, build, _buildActionButtons, _buildDownloadingView, _buildErrorView, _buildInstallingView, createState, _dismiss (+21 more)

### Community 76 - "badges_screen.dart"
Cohesion: 0.09
Nodes (18): BadgeCategory, _BadgesSketchProgressBarPainter, _buildBadgeCard, _buildCategoryChip, createState, fillColor, initialCategory, initState (+10 more)

### Community 77 - "Pinpoint Logic Module"
Cohesion: 0.29
Nodes (6): _, calculateScore, isCorrectGuess, normalize, PinpointLogic, validateLevel

### Community 78 - "update_service.dart"
Cohesion: 0.06
Nodes (29): apkUrl, AppUpdateInfo, changelog, checkForUpdate, compareSemver, currentBuildNumber, currentVersion, _dismissedBuildNumberInSession (+21 more)

### Community 79 - "dailyPlayServiceProvider"
Cohesion: 0.28
Nodes (22): badgeServiceProvider, buildProgressPayload, CloudBackupNotifier, dailyPlayServiceProvider, gameStatsServiceProvider, _checkSundayWeeklyReport, leaderboardServiceProvider, _BadgesScreenState (+14 more)

### Community 80 - "api_client.dart"
Cohesion: 0.06
Nodes (31): _authToken, _authTokenKey, _cachedBaseUrl, _cachedNickname, _cachedRecoveryCode, checkConnectionAndTimeSync, checkNicknameAvailability, _client (+23 more)

### Community 82 - "Win32 Window Module"
Cohesion: 0.50
Nodes (3): Point, x, y

### Community 83 - "cloud_backup_service.dart"
Cohesion: 0.12
Nodes (13): _backupSignatureSalt, CloudBackupState, copyWith, decodePortableBackupKey, deriveDeterministicCodeFromDeviceId, exportPortableBackupKey, isSyncing, lastMessage (+5 more)

### Community 84 - "ConsumerStatefulWidget"
Cohesion: 0.12
Nodes (16): apiClientProvider, _init, NicknamePromptDialog, _NicknamePromptDialogState, _submit, _checkMandatoryNickname, HomeScreen, _HomeScreenState (+8 more)

### Community 86 - "base_game.dart"
Cohesion: 0.09
Nodes (21): GameCognitiveDomainExt, bestTimeMs, completedAt, difficulty, durationMs, fromJson, GameResult, gamesPlayed (+13 more)

### Community 89 - "package.json"
Cohesion: 0.10
Nodes (20): concurrently, @laravel/multiplex, laravel-vite-plugin, tailwindcss, @tailwindcss/vite, vite, devDependencies, concurrently (+12 more)

### Community 92 - "require"
Cohesion: 0.33
Nodes (5): require, laravel/framework, laravel/sanctum, laravel/tinker, php

### Community 93 - "ApiTest"
Cohesion: 0.19
Nodes (3): ApiTest, ExampleTest, TestCase

### Community 104 - "player_server_stats.dart"
Cohesion: 0.12
Nodes (15): allTimeScore, avgDurationMs, bestScore, bestTimeMs, fromJson, games, GameServerStats, gamesPlayed (+7 more)

### Community 105 - "backup_restore_dialog.dart"
Cohesion: 0.13
Nodes (16): cloudBackupProvider, BackupRestoreDialog, _BackupRestoreDialogState, build, createState, dispose, _feedbackMessage, _formatLastSync (+8 more)

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

### Community 114 - "weekly_brain_report_dialog.dart"
Cohesion: 0.05
Nodes (42): barColor, _buildShareText, _buildWobblyBarPath, calculate, _CognitiveDomainBar, cognitiveFocusPercent, darkBgColor, gamePuzzlesSolved (+34 more)

### Community 115 - "game_card_logos.dart"
Cohesion: 0.11
Nodes (17): animate, build, _drawDoodlePuffCloud, _drawDoodleQuestion, _drawFreehandSparkle, GameBackgroundLogo, gameType, _getPainter (+9 more)

### Community 118 - "psr-4"
Cohesion: 0.40
Nodes (5): autoload, psr-4, App\\, Database\\Factories\\, Database\\Seeders\\

### Community 120 - "nickname_prompt_dialog.dart"
Cohesion: 0.17
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

### Community 134 - "userNicknameProvider"
Cohesion: 0.15
Nodes (18): networkCheckerProvider, applyProgressPayload, playerStatsServiceProvider, retentionNotificationProvider, soundHapticProvider, userNicknameProvider, build, HeadToHeadShareDialog (+10 more)

### Community 135 - "head_to_head_share_dialog.dart"
Cohesion: 0.08
Nodes (20): GameStatsUpdateResult, bgColor, _buildShareText, dateId, difficulty, durationMs, fallbackIQ, gameTitle (+12 more)

### Community 136 - "leagueServiceProvider"
Cohesion: 0.15
Nodes (16): leagueServiceProvider, nextResetCountdownProvider, timeSyncServiceProvider, build, SketchCountdownTimer, _advanceToNextDay, build, _GeniusLobbyTab (+8 more)

### Community 137 - "player_stats_service.dart"
Cohesion: 0.11
Nodes (13): ApiClient, apiClient, initialize, _isRefreshing, _loadFromLocal, notifier, _prefKey, refreshStats (+5 more)

### Community 138 - "badge_service.dart"
Cohesion: 0.12
Nodes (12): awardBadge, evaluateBadges, exportBackupMap, _findDef, isUnlocked, _loadBadges, _prefKey, remainingDays (+4 more)

### Community 139 - "main.dart"
Cohesion: 0.22
Nodes (4): themeServiceProvider, build, DailyGamesApp, main

### Community 141 - "dart:math"
Cohesion: 0.22
Nodes (7): _, derive, devSecret, fingerprint, PuzzleSeed, random, toInt

### Community 143 - "dart:async"
Cohesion: 0.20
Nodes (5): _connectivity, dispose, _init, _subscription, _updateState

### Community 144 - "_"
Cohesion: 0.22
Nodes (8): _, _createDeterministicFallback, generate, _generateEdgeWalls, _generateHamiltonianPath, maxAttempts, _placeCheckpoints, ZipGenerator

### Community 145 - "Map"
Cohesion: 0.20
Nodes (8): PlayerServerStats, NetworkCheckerNotifier, BadgeNotifier, GameStatsNotifier, PlayerStatsNotifier, ThemeNotifier, UserNicknameNotifier, GameStatsNotifierTestExt

### Community 146 - "zip_logic.dart"
Cohesion: 0.40
Nodes (3): countSolutions, validatePath, ZipLogic

### Community 149 - "List"
Cohesion: 0.25
Nodes (6): alternativeAnswers, categoryHint, clues, id, PinpointLevel, targetWord

## Knowledge Gaps
- **1554 isolated node(s):** `DailyBadge`, `UserBadge`, `label`, `subtitle`, `id` (+1549 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 1931 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **38 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `_` connect `Patches Generator Module` to `Patches Levels Module`, `Crossclimb Generator & Pinpoint Generator`, `dart:math`, `_`?**
  _High betweenness centrality (0.023) - this node is a cross-community bridge._
- **Are the 37 inferred relationships involving `Kara Kalem Eskiz Defteri Design Language` (e.g. with `mipmap-hdpi/ic_launcher.png` and `mipmap-mdpi/ic_launcher.png`) actually correct?**
  _`Kara Kalem Eskiz Defteri Design Language` has 37 INFERRED edges - model-reasoned connections that need verification._
- **What connects `DailyBadge`, `UserBadge`, `label` to the rest of the system?**
  _1554 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Color Theme & Palette Tokens` be split into smaller, more focused modules?**
  _Cohesion score 0.02247191011235955 - nodes in this community are weakly interconnected._
- **Why does `Win32Window` connect `win32_window.cpp` to `Win32 Window Module`, `Win32 Window & Main`, `Win32 Window Module`, `Win32 Window & Flutter Window`?**
  _High betweenness centrality (0.016) - this node is a cross-community bridge._
- **Should `Queens Screen & Solver UI` be split into smaller, more focused modules?**
  _Cohesion score 0.02531645569620253 - nodes in this community are weakly interconnected._
- **Why does `GameType` connect `base_game.dart` to `badge_model.dart`, `completed_game_leaderboard_dialog.dart`, `head_to_head_share_dialog.dart`, `leaderboard_screen.dart`, `Game Stats & IQ Milestone Service`, `Home Screen Hub & Nav Providers`, `leaderboard_service.dart`, `weekly_brain_report_dialog.dart`, `game_card_logos.dart`, `home_brain_hero_card.dart`, `../../core/widgets/sketch_decorations.dart`, `Daily Play Service Module`?**
  _High betweenness centrality (0.007) - this node is a cross-community bridge._