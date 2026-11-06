# Graph Report - daily  (2026-11-06)

## Corpus Check
- 176 files · ~141,380 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 74 file(s) not represented in the graph (top: (none) 24, .xml 9, .xcconfig 8)

## Summary
- 2338 nodes · 3315 edges · 143 communities (104 shown, 39 thin omitted)
- Extraction: 98% EXTRACTED · 2% INFERRED · 0% AMBIGUOUS · INFERRED: 73 edges (avg confidence: 0.78)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `1bd3ddeb`
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
- Leaderboard Service Test &
- Daily Play Service Module
- game_logic_test.dart
- genius_win_dialog.dart
- Win32 Window & Flutter Window
- Ilerleme & Pubspec
- List
- Crossclimb Levels & Pinpoint Levels
- queens_lobby_screen.dart
- Win32 Window Module
- App Button & App Theme
- badge_service.dart
- Profile Screen Module
- Leaderboard Screen Module
- Patches Models & Patches Logic
- game_card_logos.dart
- app_button.dart
- Crossclimb Generator & Pinpoint Generator
- App Card Module
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
- zip_logic.dart
- Neo Game Layout Module
- Patches Generator Module
- Player
- theme_service.dart
- Crossclimb Models Module
- Manifest Module
- ../../games/common/base_game.dart
- Tango Logic Module
- Crossclimb Logic Module
- Puzzle Seed Module
- Daily Play Service &
- Puzzle Repository & Zip Levels
- Tango Generator Module
- Zip Generator Module
- Illuminate\Database\Schema\Blueprint
- update_prompt_dialog.dart
- Patches Generator Test &
- badges_screen.dart
- Pinpoint Logic Module
- update_service.dart
- leaderboardServiceProvider
- api_client.dart
- Pinpoint Test Module
- Win32 Window Module
- Mainactivity Module
- completed_game_leaderboard_dialog.dart
- base_game.dart
- Ilerleme & Readme
- User
- package.json
- require
- ApiTest
- Readme Module
- LaunchImage.imageset/README.md
- dart:async
- State
- composer.json
- scripts
- require-dev
- README.md
- queens_board_painter.dart
- config
- dart:convert
- AppServiceProvider
- main.dart
- queens_test.dart
- psr-4
- nickname_prompt_dialog.dart
- ExampleTest
- Laravel Application
- Laravel Application
- autoload-dev
- extra
- ProfileScreen
- ConsumerState
- ../../core/utils/date_utils.dart
- user_nickname_provider.dart
- leagueServiceProvider
- package:flutter_riverpod/flutter_riverpod.dart
- _launchGame
- SketchSurfaceScope

## God Nodes (most connected - your core abstractions)
1. `Kara Kalem Eskiz Defteri Design Language` - 37 edges
2. `leaderboardServiceProvider` - 24 edges
3. `dailyPlayServiceProvider` - 22 edges
4. `Win32Window` - 21 edges
5. `badgeServiceProvider` - 19 edges
6. `gameStatsServiceProvider` - 19 edges
7. `_` - 19 edges
8. `Player` - 19 edges
9. `_` - 16 edges
10. `_` - 14 edges

## Surprising Connections (you probably didn't know these)
- `📌 1. Projenin Genel Durumu ve Yapılanlar` --references--> `GameScore`  [INFERRED]
  VPS_KURULUMU_VE_DURUM.md → server/app/Models/GameScore.php
- `📌 1. Projenin Genel Durumu ve Yapılanlar` --references--> `Player`  [INFERRED]
  VPS_KURULUMU_VE_DURUM.md → server/app/Models/Player.php
- `🌐 4. Canlı VPS Sunucu Durumu (AKTİF & ÇALIŞIYOR)` --references--> `RealisticBotSeeder`  [INFERRED]
  VPS_KURULUMU_VE_DURUM.md → server/database/seeders/RealisticBotSeeder.php
- `build` --references--> `themeServiceProvider`  [EXTRACTED]
  lib/main.dart → lib/core/services/theme_service.dart
- `_triggerRefresh` --references--> `leaderboardServiceProvider`  [EXTRACTED]
  lib/features/leaderboard/leaderboard_screen.dart → lib/features/leaderboard/leaderboard_service.dart

## Import Cycles
- None detected.

## Hyperedges (group relationships)
- **The 6 Daily Puzzle Games** — readme_game_queens, readme_game_tango, readme_game_zip, readme_game_pinpoint, readme_game_crossclimb, readme_game_patches [EXTRACTED 1.00]
- **Zühtü Gamification & Motivation Architecture** — ilerleme_league_system, ilerleme_iq_index_system, ilerleme_steam_badge_system, rozetler_championship_belts, rozetler_streak_badges [INFERRED 0.95]

## Communities (143 total, 39 thin omitted)

### Community 0 - "Color Theme & Palette Tokens"
Cohesion: 0.02
Nodes (85): accentAmber, accentCyan, accentGreen, accentOrange, accentPink, accentPurple, adaptive, AppColors (+77 more)

### Community 1 - "Queens Screen & Solver UI"
Cohesion: 0.03
Nodes (72): activeColor, _activeHintIsWarning, _activeHintMessage, _activeHintTitle, _applyDragToCell, build, _buildCellContent, _buildHintInfoCard (+64 more)

### Community 2 - "Sketch Paper & Notebook Theme"
Cohesion: 0.04
Nodes (44): backgroundColor, borderColor, borderRadius, borderWidth, build, _buildOrganicPath, _buildWobblyPath, centerChild (+36 more)

### Community 3 - "badge_model.dart"
Cohesion: 0.07
Nodes (24): allBadges, artType, BadgeCategory, badgeId, _buildStreakBadges, category, color, DailyBadge (+16 more)

### Community 4 - "Weekly League & Bot Engine"
Cohesion: 0.04
Nodes (47): _allBotNames, apiClient, _buildLeaguePlayers, _calculateUserWeeklyScore, checkWeekTransition, clearPendingLeagueChange, copyWith, currentLevel (+39 more)

### Community 5 - "Patches Screen & Grid Division"
Cohesion: 0.05
Nodes (39): build, _buildRuleCard, _buildShapeMiniIcon, _cellFromOffset, _checkState, color, createState, didChangeAppLifecycleState (+31 more)

### Community 6 - "Core Sketch Controls & Win Dialog"
Cohesion: 0.07
Nodes (27): _animController, build, child, color, _ConfettiPainter, _ConfettiParticle, _controller, createState (+19 more)

### Community 7 - "Tango Screen & Grid Controls"
Cohesion: 0.05
Nodes (38): build, _buildRuleCard, _buildSymbol, c, _cachedSolution, _checkState, _conflictDebounceTimer, createState (+30 more)

### Community 9 - "League Promotion Ladder UI"
Cohesion: 0.05
Nodes (35): LeaguePlayer, _animController, _avatarEmoji, backgroundColor, barBackgroundColor, _buildRankWidget, _buildWobblyRect, color (+27 more)

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
Cohesion: 0.04
Nodes (54): all, artType, bestDurationMs, bestScore, betterThanPercent, copyWith, _createInitialState, credibility (+46 more)

### Community 14 - "Home Screen Hub & Nav Providers"
Cohesion: 0.06
Nodes (20): GamePerformanceData, _bottomNavIndex, _checkAppUpdate, color, createState, game, icon, initState (+12 more)

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
Cohesion: 0.10
Nodes (20): advanceDay, _clockDriftSeconds, controller, _dayOffset, emit, formatCountdown, getTimeUntilNextReset, getTodayDateId (+12 more)

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
Nodes (47): accentColor, build, _buildWobblySeal, color, _drawDashedPath, _drawFivePointStar, _drawMiniSpark, isDark (+39 more)

### Community 24 - "Zip Path Grid & Difficulty Models"
Cohesion: 0.09
Nodes (20): col, difficulty, edgeWalls, fromJson, gridSize, hashCode, id, numberPoints (+12 more)

### Community 25 - "Sketch Decorations & Queens Screen"
Cohesion: 0.07
Nodes (29): SketchBadgeIcon, SketchBadgeMedallion, SketchDoodleLock, SketchCard, SketchCircularDoodle, SketchDoodleBrain, SketchDoodleCrown, SketchDoodleFlame (+21 more)

### Community 26 - "Home Screen & Zip Screen"
Cohesion: 0.07
Nodes (27): _DoodleLockPainter, _SketchBadgeArtPainter, _WobblyBadgeMedallionPainter, _DoodleBrainPainter, _DoodleCrownPainter, _DoodleFlamePainter, _DoodleTrophyPainter, _SketchNotebookPainter (+19 more)

### Community 27 - "Leaderboard Service Test &"
Cohesion: 0.11
Nodes (8): main, main, main, main, main, main, main, main

### Community 28 - "Daily Play Service Module"
Cohesion: 0.08
Nodes (25): completedAt, copyWith, DailyPlayNotifier, DailyPlayRecord, DailyPlayState, dateId, durationMs, _formatDateKey (+17 more)

### Community 29 - "game_logic_test.dart"
Cohesion: 0.10
Nodes (5): main, main, main, main, main

### Community 30 - "genius_win_dialog.dart"
Cohesion: 0.07
Nodes (23): GameStatsUpdateResult, badgeColor, build, _buildAnimatedIQMilestoneCard, createState, fillColor, gameTitle, icon (+15 more)

### Community 31 - "Win32 Window & Flutter Window"
Cohesion: 0.11
Nodes (4): FlutterWindow, flutter_controller_, FlutterWindow::FlutterWindow(), project_

### Community 32 - "Ilerleme & Pubspec"
Cohesion: 0.14
Nodes (17): Realistic IQ Index & Gaussian Distribution, Duolingo Style Weekly League System, Steam Style Badge & Championship Belt Room, flutter_riverpod dependency, shared_preferences dependency, Crossclimb (Kelime Tırmanışı), Patches (Alan Bölme), Pinpoint (Kelime İzleri) (+9 more)

### Community 33 - "List"
Cohesion: 0.25
Nodes (6): alternativeAnswers, categoryHint, clues, id, PinpointLevel, targetWord

### Community 34 - "Crossclimb Levels & Pinpoint Levels"
Cohesion: 0.12
Nodes (11): _cache, CrossclimbLevelRepository, getDaily, getLevelForDate, _presets, _cache, getDaily, getLevelForDate (+3 more)

### Community 35 - "queens_lobby_screen.dart"
Cohesion: 0.11
Nodes (14): _activeLeaderboardTab, _buildDifficultyCard, _buildDifficultyLogo, _buildRuleItem, createState, _getDiffColor, _getGridSize, initState (+6 more)

### Community 36 - "Win32 Window Module"
Cohesion: 0.13
Nodes (8): Scale(), Size, height, width, Win32Window::Win32Window(), WindowClassRegistrar, class_registered_, instance_

### Community 37 - "App Button & App Theme"
Cohesion: 0.11
Nodes (12): AppTextStyles, bodyLarge, bodyMedium, displayLarge, headlineLarge, headlineMedium, labelLarge, titleLarge (+4 more)

### Community 38 - "badge_service.dart"
Cohesion: 0.12
Nodes (10): awardBadge, evaluateBadges, _findDef, isUnlocked, _loadBadges, _prefKey, remainingDays, revokeBadge (+2 more)

### Community 39 - "Profile Screen Module"
Cohesion: 0.09
Nodes (15): _checkUpdate, createState, fillColor, icon, initState, _isChecking, isSelected, _loadVersion (+7 more)

### Community 40 - "Leaderboard Screen Module"
Cohesion: 0.11
Nodes (17): build, _buildEntryCard, _buildQueensDifficultyChip, _buildSeparator, createState, crownWidget, entry, fillColor (+9 more)

### Community 41 - "Patches Models & Patches Logic"
Cohesion: 0.12
Nodes (16): _backtrack, clue, _ClueCandidates, countSolutions, _findCandidatesForClue, getClueCountInRect, hasOverlap, isValidRect (+8 more)

### Community 42 - "game_card_logos.dart"
Cohesion: 0.11
Nodes (17): animate, build, _drawDoodlePuffCloud, _drawDoodleQuestion, _drawFreehandSparkle, GameBackgroundLogo, gameType, _getPainter (+9 more)

### Community 43 - "app_button.dart"
Cohesion: 0.13
Nodes (9): AppTheme, build, createState, icon, isFullWidth, _isPressed, isPrimary, onPressed (+1 more)

### Community 44 - "Crossclimb Generator & Pinpoint Generator"
Cohesion: 0.15
Nodes (10): _, CrossclimbGenerator, _epoch, generate, pool, _, _epoch, generate (+2 more)

### Community 45 - "App Card Module"
Cohesion: 0.14
Nodes (12): backgroundColor, borderColor, build, child, createState, _handleTapCancel, _handleTapDown, _handleTapUp (+4 more)

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
Cohesion: 0.11
Nodes (14): advanceToNextDay, _customDate, _dayOffset, formatCountdown, formatGameTime, GameDateUtils, getActiveDate, getFormattedDate (+6 more)

### Community 56 - "Queens Levels Module"
Cohesion: 0.17
Nodes (10): _cache, _epoch, getDaily, getDifficultyForDate, getDifficultyForDays, getLevelForDate, getLevelForDateAndDifficulty, _pick (+2 more)

### Community 57 - "zip_logic.dart"
Cohesion: 0.40
Nodes (3): countSolutions, validatePath, ZipLogic

### Community 58 - "Neo Game Layout Module"
Cohesion: 0.18
Nodes (7): build, child, gameType, levelId, NeoGameLayout, onRestart, statsBar

### Community 60 - "Patches Generator Module"
Cohesion: 0.18
Nodes (9): _, area, generate, _generateTiling, h, maxAttempts, PatchesGenerator, _RectDim (+1 more)

### Community 61 - "Player"
Cohesion: 0.06
Nodes (20): AuthController, GameController, LeaderboardController, Controller, GameScore, {closure#1}(), Player, {closure#1}() (+12 more)

### Community 62 - "theme_service.dart"
Cohesion: 0.20
Nodes (6): currentMode, _loadFromPrefs, _prefKey, setThemeMode, ThemeNotifier, toggleTheme

### Community 63 - "Crossclimb Models Module"
Cohesion: 0.18
Nodes (10): changedIndex, clue, CrossclimbLevel, CrossclimbStep, endWord, id, index, startWord (+2 more)

### Community 64 - "Manifest Module"
Cohesion: 0.18
Nodes (10): background_color, description, display, icons, name, orientation, prefer_related_applications, short_name (+2 more)

### Community 65 - "../../games/common/base_game.dart"
Cohesion: 0.20
Nodes (8): clearSession, GameSessionService, gameSessionServiceProvider, loadSession, _makeKey, _prefix, saveSession, updateElapsedMs

### Community 66 - "Tango Logic Module"
Cohesion: 0.20
Nodes (8): countSolutions, findConflicts, _hasIdenticalLines, isPlacementValid, solve, solveDeductively, TangoLogic, validateGrid

### Community 67 - "Crossclimb Logic Module"
Cohesion: 0.22
Nodes (8): _, calculateScore, CrossclimbLogic, findChangedIndex, hammingDistance, isStepValid, normalize, validateLevel

### Community 68 - "Puzzle Seed Module"
Cohesion: 0.22
Nodes (7): _, derive, devSecret, fingerprint, PuzzleSeed, random, toInt

### Community 69 - "Daily Play Service &"
Cohesion: 0.29
Nodes (6): NetworkCheckerNotifier, BadgeNotifier, GameStatsNotifier, LeagueNotifier, LeagueState, UserNicknameNotifier

### Community 70 - "Puzzle Repository & Zip Levels"
Cohesion: 0.22
Nodes (8): getDaily, PuzzleRepository, LocalCrossclimbPuzzleRepository, LocalPatchesPuzzleRepository, LocalPinpointPuzzleRepository, LocalQueensPuzzleRepository, LocalTangoPuzzleRepository, LocalZipPuzzleRepository

### Community 71 - "Tango Generator Module"
Cohesion: 0.22
Nodes (7): _, _extractPotentialConstraints, generate, _generateFullSolution, maxAttempts, _rowMatchesAnyPrevious, TangoGenerator

### Community 72 - "Zip Generator Module"
Cohesion: 0.20
Nodes (8): _, _createDeterministicFallback, generate, _generateEdgeWalls, _generateHamiltonianPath, maxAttempts, _placeCheckpoints, ZipGenerator

### Community 73 - "Illuminate\Database\Schema\Blueprint"
Cohesion: 0.09
Nodes (13): {closure#1}(), {closure#2}(), {closure#3}(), {closure#1}(), {closure#2}(), {closure#1}(), {closure#2}(), {closure#3}() (+5 more)

### Community 74 - "update_prompt_dialog.dart"
Cohesion: 0.06
Nodes (30): AppUpdateInfo, bgColor, build, _buildActionButtons, _buildDownloadingView, _buildErrorView, _buildInstallingView, createState (+22 more)

### Community 76 - "badges_screen.dart"
Cohesion: 0.09
Nodes (17): _BadgesSketchProgressBarPainter, _buildBadgeCard, _buildCategoryChip, createState, fillColor, initialCategory, initState, _onlyUnlocked (+9 more)

### Community 77 - "Pinpoint Logic Module"
Cohesion: 0.29
Nodes (6): _, calculateScore, isCorrectGuess, normalize, PinpointLogic, validateLevel

### Community 78 - "update_service.dart"
Cohesion: 0.06
Nodes (28): apkUrl, changelog, checkForUpdate, compareSemver, currentBuildNumber, currentVersion, _dismissedBuildNumberInSession, dismissThisSession (+20 more)

### Community 79 - "leaderboardServiceProvider"
Cohesion: 0.19
Nodes (26): badgeServiceProvider, dailyPlayServiceProvider, gameStatsServiceProvider, leaderboardServiceProvider, build, CrossclimbScreen, _CrossclimbScreenState, _handleWin (+18 more)

### Community 80 - "api_client.dart"
Cohesion: 0.07
Nodes (25): _authToken, _authTokenKey, _cachedBaseUrl, _cachedNickname, checkConnectionAndTimeSync, checkNicknameAvailability, _client, _defaultLiveUrl (+17 more)

### Community 82 - "Win32 Window Module"
Cohesion: 0.50
Nodes (3): Point, x, y

### Community 84 - "completed_game_leaderboard_dialog.dart"
Cohesion: 0.13
Nodes (10): build, createState, difficulty, durationMs, game, initState, levelId, score (+2 more)

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
Cohesion: 0.21
Nodes (3): ApiTest, ExampleTest, TestCase

### Community 104 - "dart:async"
Cohesion: 0.20
Nodes (5): _connectivity, dispose, _init, _subscription, _updateState

### Community 105 - "State"
Cohesion: 0.23
Nodes (10): AppButton, _AppButtonState, AppCard, _AppCardState, GeniusWinDialog, _GeniusWinDialogState, _GeniusGameButton, _GeniusGameButtonState (+2 more)

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

### Community 114 - "main.dart"
Cohesion: 0.13
Nodes (3): child, build, main

### Community 118 - "psr-4"
Cohesion: 0.40
Nodes (5): autoload, psr-4, App\\, Database\\Factories\\, Database\\Seeders\\

### Community 120 - "nickname_prompt_dialog.dart"
Cohesion: 0.15
Nodes (12): apiClientProvider, build, _controller, createState, dispose, _errorMessage, isEditing, _isLoading (+4 more)

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

### Community 134 - "ProfileScreen"
Cohesion: 0.21
Nodes (12): networkCheckerProvider, themeServiceProvider, userNicknameProvider, initState, build, OnlineGuardWidget, build, LeagueProfileCard (+4 more)

### Community 135 - "ConsumerState"
Cohesion: 0.23
Nodes (10): _GeniusLobbyTab, _GeniusLobbyTabState, HomeScreen, _HomeScreenState, LeaderboardScreen, _LeaderboardScreenState, CompletedGameLeaderboardDialog, _CompletedGameLeaderboardDialogState (+2 more)

### Community 136 - "../../core/utils/date_utils.dart"
Cohesion: 0.20
Nodes (7): build, customDetailText, entry, isMe, LeaderboardEntryCard, showThreeOfThree, LeaderboardEntry

### Community 137 - "user_nickname_provider.dart"
Cohesion: 0.29
Nodes (5): ApiClient, apiClient, _loadInitialNickname, _nicknameKey, setNickname

### Community 138 - "leagueServiceProvider"
Cohesion: 0.33
Nodes (6): leagueServiceProvider, _advanceToNextDay, build, initState, LeagueScreen, _LeagueScreenState

### Community 141 - "_launchGame"
Cohesion: 0.50
Nodes (3): _launchGame, build, _launchQueens

## Knowledge Gaps
- **1325 isolated node(s):** `DailyBadge`, `UserBadge`, `label`, `subtitle`, `id` (+1320 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 1671 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **39 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Win32Window` connect `win32_window.cpp` to `Win32 Window Module`, `Win32 Window & Main`, `Win32 Window Module`, `Win32 Window & Flutter Window`?**
  _High betweenness centrality (0.011) - this node is a cross-community bridge._
- **Are the 37 inferred relationships involving `Kara Kalem Eskiz Defteri Design Language` (e.g. with `mipmap-hdpi/ic_launcher.png` and `mipmap-mdpi/ic_launcher.png`) actually correct?**
  _`Kara Kalem Eskiz Defteri Design Language` has 37 INFERRED edges - model-reasoned connections that need verification._
- **What connects `DailyBadge`, `UserBadge`, `label` to the rest of the system?**
  _1325 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Color Theme & Palette Tokens` be split into smaller, more focused modules?**
  _Cohesion score 0.02247191011235955 - nodes in this community are weakly interconnected._
- **Why does `GameType` connect `base_game.dart` to `badge_model.dart`, `Leaderboard Screen Module`, `game_card_logos.dart`, `Game Stats & IQ Milestone Service`, `Home Screen Hub & Nav Providers`, `leaderboard_service.dart`, `completed_game_leaderboard_dialog.dart`, `home_brain_hero_card.dart`, `Neo Game Layout Module`, `Daily Play Service Module`?**
  _High betweenness centrality (0.009) - this node is a cross-community bridge._
- **Should `Queens Screen & Solver UI` be split into smaller, more focused modules?**
  _Cohesion score 0.02531645569620253 - nodes in this community are weakly interconnected._
- **Why does `LeaderboardService` connect `leaderboard_service.dart` to `Weekly League & Bot Engine`?**
  _High betweenness centrality (0.009) - this node is a cross-community bridge._