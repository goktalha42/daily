# Graph Report - daily  (2026-11-05)

## Corpus Check
- 172 files · ~125,812 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 72 file(s) not represented in the graph (top: (none) 24, .xml 9, .xcconfig 8)

## Summary
- 2180 nodes · 3100 edges · 130 communities (94 shown, 36 thin omitted)
- Extraction: 98% EXTRACTED · 2% INFERRED · 0% AMBIGUOUS · INFERRED: 73 edges (avg confidence: 0.78)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `4c2e875e`
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
- Win32Window
- Linux Desktop Runner & Engine
- home_brain_hero_card.dart
- .MessageHandler
- Zip Path Grid & Difficulty Models
- Sketch Decorations & Queens Screen
- Home Screen & Zip Screen
- Leaderboard Service Test &
- Daily Play Service Module
- game_logic_test.dart
- Game Stats Service &
- Win32 Window & Flutter Window
- Ilerleme & Pubspec
- List
- Crossclimb Levels & Pinpoint Levels
- Game Card Logos Module
- Win32 Window Module
- App Button & App Theme
- package:google_fonts/google_fonts.dart
- Profile Screen Module
- Leaderboard Screen Module
- Patches Models & Patches Logic
- Badge Service Module
- Date Utils Module
- Crossclimb Generator & Pinpoint Generator
- App Card Module
- queens_lobby_screen.dart
- leaderboard_service.dart
- App Spacing Module
- Patches Levels Module
- _
- Main & Utils
- Widget Test & Theme Service
- Tango Levels Module
- Zip Levels Module
- user_nickname_provider.dart
- Queens Levels Module
- zip_logic.dart
- Neo Game Layout Module
- Patches Generator Module
- Player
- Size
- Crossclimb Models Module
- Manifest Module
- Game Session Service Module
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
- Crossclimb Test Module
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
- composer.json
- scripts
- require-dev
- README.md
- main.dart
- config
- dart:convert
- AppServiceProvider
- psr-4
- ExampleTest
- Laravel Application
- Laravel Application
- autoload-dev
- extra

## God Nodes (most connected - your core abstractions)
1. `Kara Kalem Eskiz Defteri Design Language` - 37 edges
2. `leaderboardServiceProvider` - 24 edges
3. `dailyPlayServiceProvider` - 22 edges
4. `Win32Window` - 21 edges
5. `badgeServiceProvider` - 19 edges
6. `_` - 19 edges
7. `Player` - 19 edges
8. `gameStatsServiceProvider` - 17 edges
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
- `initState` --references--> `userNicknameProvider`  [EXTRACTED]
  lib/core/widgets/nickname_prompt_dialog.dart → lib/core/services/user_nickname_provider.dart

## Import Cycles
- None detected.

## Hyperedges (group relationships)
- **The 6 Daily Puzzle Games** — readme_game_queens, readme_game_tango, readme_game_zip, readme_game_pinpoint, readme_game_crossclimb, readme_game_patches [EXTRACTED 1.00]
- **Zühtü Gamification & Motivation Architecture** — ilerleme_league_system, ilerleme_iq_index_system, ilerleme_steam_badge_system, rozetler_championship_belts, rozetler_streak_badges [INFERRED 0.95]

## Communities (130 total, 36 thin omitted)

### Community 0 - "Color Theme & Palette Tokens"
Cohesion: 0.02
Nodes (85): accentAmber, accentCyan, accentGreen, accentOrange, accentPink, accentPurple, adaptive, AppColors (+77 more)

### Community 1 - "Queens Screen & Solver UI"
Cohesion: 0.03
Nodes (72): activeColor, _activeHintIsWarning, _activeHintMessage, _activeHintTitle, _applyDragToCell, build, _buildCellContent, _buildHintInfoCard (+64 more)

### Community 2 - "Sketch Paper & Notebook Theme"
Cohesion: 0.04
Nodes (45): backgroundColor, borderColor, borderRadius, borderWidth, build, _buildOrganicPath, _buildWobblyPath, centerChild (+37 more)

### Community 3 - "badge_model.dart"
Cohesion: 0.08
Nodes (23): allBadges, badgeId, _buildStreakBadges, category, color, DailyBadge, description, emoji (+15 more)

### Community 4 - "Weekly League & Bot Engine"
Cohesion: 0.04
Nodes (47): _allBotNames, apiClient, _buildLeaguePlayers, _calculateUserWeeklyScore, checkWeekTransition, clearPendingLeagueChange, copyWith, currentLevel (+39 more)

### Community 5 - "Patches Screen & Grid Division"
Cohesion: 0.05
Nodes (39): build, _buildRuleCard, _buildShapeMiniIcon, _cellFromOffset, _checkState, color, createState, didChangeAppLifecycleState (+31 more)

### Community 6 - "Core Sketch Controls & Win Dialog"
Cohesion: 0.06
Nodes (37): AppButton, _AppButtonState, AppCard, _AppCardState, _animController, build, child, color (+29 more)

### Community 7 - "Tango Screen & Grid Controls"
Cohesion: 0.05
Nodes (38): build, _buildRuleCard, _buildSymbol, c, _cachedSolution, _checkState, _conflictDebounceTimer, createState (+30 more)

### Community 9 - "League Promotion Ladder UI"
Cohesion: 0.05
Nodes (41): LeaguePlayer, leagueServiceProvider, _advanceToNextDay, _animController, _avatarEmoji, backgroundColor, barBackgroundColor, build (+33 more)

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
Cohesion: 0.06
Nodes (30): all, bestDurationMs, bestScore, betterThanPercent, _createInitialState, currentIQ, currentMilestone, detectNewMilestone (+22 more)

### Community 14 - "Home Screen Hub & Nav Providers"
Cohesion: 0.06
Nodes (19): _bottomNavIndex, _checkAppUpdate, color, createState, game, icon, initState, isCompleted (+11 more)

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

### Community 20 - "Win32Window"
Cohesion: 0.27
Nodes (4): Win32Window, child_content_, quit_on_close_, window_handle_

### Community 21 - "Linux Desktop Runner & Engine"
Cohesion: 0.10
Nodes (13): main(), first_frame_cb(), my_application_activate(), my_application_class_init(), my_application_dispose(), my_application_init(), my_application_local_command_line(), my_application_new() (+5 more)

### Community 22 - "home_brain_hero_card.dart"
Cohesion: 0.12
Nodes (14): activeDateKey, build, dailyPlayState, game, _getBadgeInfo, HomeBrainHeroCard, index, isDark (+6 more)

### Community 24 - "Zip Path Grid & Difficulty Models"
Cohesion: 0.09
Nodes (20): col, difficulty, edgeWalls, fromJson, gridSize, hashCode, id, numberPoints (+12 more)

### Community 25 - "Sketch Decorations & Queens Screen"
Cohesion: 0.09
Nodes (22): SketchCard, SketchCircularDoodle, SketchDoodleBrain, SketchDoodleCrown, SketchDoodleFlame, SketchDoodleTrophy, SketchPaperBackground, SketchPlaceholderBox (+14 more)

### Community 26 - "Home Screen & Zip Screen"
Cohesion: 0.09
Nodes (21): _DoodleBrainPainter, _DoodleCrownPainter, _DoodleFlamePainter, _DoodleTrophyPainter, _SketchNotebookPainter, _SketchPlaceholderPainter, _WobblySketchBoxPainter, _WobblySketchCirclePainter (+13 more)

### Community 27 - "Leaderboard Service Test &"
Cohesion: 0.13
Nodes (7): main, main, main, main, main, main, main

### Community 28 - "Daily Play Service Module"
Cohesion: 0.09
Nodes (21): completedAt, copyWith, DailyPlayRecord, dateId, durationMs, _formatDateKey, fromJson, gameType (+13 more)

### Community 29 - "game_logic_test.dart"
Cohesion: 0.11
Nodes (5): main, _dateId, main, main, main

### Community 30 - "Game Stats Service &"
Cohesion: 0.06
Nodes (26): GameStatsUpdateResult, badgeColor, build, _buildAnimatedIQMilestoneCard, createState, gameTitle, GeniusWinDialog, _GeniusWinDialogState (+18 more)

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

### Community 35 - "Game Card Logos Module"
Cohesion: 0.11
Nodes (17): animate, build, _drawDoodlePuffCloud, _drawDoodleQuestion, _drawFreehandSparkle, GameBackgroundLogo, gameType, _getPainter (+9 more)

### Community 36 - "Win32 Window Module"
Cohesion: 0.15
Nodes (5): Scale(), Win32Window::Win32Window(), WindowClassRegistrar, class_registered_, instance_

### Community 37 - "App Button & App Theme"
Cohesion: 0.09
Nodes (18): AppTextStyles, bodyLarge, bodyMedium, displayLarge, headlineLarge, headlineMedium, labelLarge, titleLarge (+10 more)

### Community 38 - "package:google_fonts/google_fonts.dart"
Cohesion: 0.29
Nodes (3): fontSize, padding, showLabel

### Community 39 - "Profile Screen Module"
Cohesion: 0.08
Nodes (18): _checkUpdate, createState, desc, fillColor, icon, initState, _isChecking, isSelected (+10 more)

### Community 40 - "Leaderboard Screen Module"
Cohesion: 0.07
Nodes (24): build, _buildEntryCard, _buildQueensDifficultyChip, _buildSeparator, createState, crownWidget, entry, fillColor (+16 more)

### Community 41 - "Patches Models & Patches Logic"
Cohesion: 0.12
Nodes (16): _backtrack, clue, _ClueCandidates, countSolutions, _findCandidatesForClue, getClueCountInRect, hasOverlap, isValidRect (+8 more)

### Community 42 - "Badge Service Module"
Cohesion: 0.12
Nodes (10): awardBadge, evaluateBadges, _findDef, isUnlocked, _loadBadges, _prefKey, remainingDays, revokeBadge (+2 more)

### Community 43 - "Date Utils Module"
Cohesion: 0.11
Nodes (14): advanceToNextDay, _customDate, _dayOffset, formatCountdown, formatGameTime, GameDateUtils, getActiveDate, getFormattedDate (+6 more)

### Community 44 - "Crossclimb Generator & Pinpoint Generator"
Cohesion: 0.15
Nodes (10): _, CrossclimbGenerator, _epoch, generate, pool, _, _epoch, generate (+2 more)

### Community 45 - "App Card Module"
Cohesion: 0.14
Nodes (12): backgroundColor, borderColor, build, child, createState, _handleTapCancel, _handleTapDown, _handleTapUp (+4 more)

### Community 46 - "queens_lobby_screen.dart"
Cohesion: 0.06
Nodes (66): apiClientProvider, networkCheckerProvider, badgeServiceProvider, dailyPlayServiceProvider, gameStatsServiceProvider, themeServiceProvider, userNicknameProvider, NicknamePromptDialog (+58 more)

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
Cohesion: 0.05
Nodes (33): _drawHandDrawnOuterFrame, _drawOrganicLine, grid, gridSize, isDark, paint, palette, QueensBoardPainter (+25 more)

### Community 51 - "Main & Utils"
Cohesion: 0.18
Nodes (4): wWinMain(), CreateAndAttachConsole(), GetCommandLineArguments(), Utf8FromUtf16()

### Community 52 - "Widget Test & Theme Service"
Cohesion: 0.20
Nodes (6): currentMode, _loadFromPrefs, _prefKey, setThemeMode, ThemeNotifier, toggleTheme

### Community 53 - "Tango Levels Module"
Cohesion: 0.15
Nodes (11): _cache, _epoch, getDaily, getDifficultyForDate, getDifficultyForDays, getLevelForDate, getLevelForDateAndDifficulty, _pick (+3 more)

### Community 54 - "Zip Levels Module"
Cohesion: 0.15
Nodes (11): _cache, _epoch, getDaily, getDifficultyForDate, getDifficultyForDays, getLevelForDate, getLevelForDateAndDifficulty, _pick (+3 more)

### Community 55 - "user_nickname_provider.dart"
Cohesion: 0.29
Nodes (5): ApiClient, apiClient, _loadInitialNickname, _nicknameKey, setNickname

### Community 56 - "Queens Levels Module"
Cohesion: 0.17
Nodes (10): _cache, _epoch, getDaily, getDifficultyForDate, getDifficultyForDays, getLevelForDate, getLevelForDateAndDifficulty, _pick (+2 more)

### Community 57 - "zip_logic.dart"
Cohesion: 0.40
Nodes (3): countSolutions, validatePath, ZipLogic

### Community 58 - "Neo Game Layout Module"
Cohesion: 0.12
Nodes (8): child, build, child, gameType, levelId, NeoGameLayout, onRestart, statsBar

### Community 60 - "Patches Generator Module"
Cohesion: 0.18
Nodes (9): _, area, generate, _generateTiling, h, maxAttempts, PatchesGenerator, _RectDim (+1 more)

### Community 61 - "Player"
Cohesion: 0.06
Nodes (20): AuthController, GameController, LeaderboardController, Controller, GameScore, {closure#1}(), Player, {closure#1}() (+12 more)

### Community 62 - "Size"
Cohesion: 0.50
Nodes (3): Size, height, width

### Community 63 - "Crossclimb Models Module"
Cohesion: 0.18
Nodes (10): changedIndex, clue, CrossclimbLevel, CrossclimbStep, endWord, id, index, startWord (+2 more)

### Community 64 - "Manifest Module"
Cohesion: 0.18
Nodes (10): background_color, description, display, icons, name, orientation, prefer_related_applications, short_name (+2 more)

### Community 65 - "Game Session Service Module"
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
Cohesion: 0.22
Nodes (8): NetworkCheckerNotifier, BadgeNotifier, DailyPlayNotifier, DailyPlayState, GameStatsNotifier, LeagueNotifier, LeagueState, UserNicknameNotifier

### Community 70 - "Puzzle Repository & Zip Levels"
Cohesion: 0.22
Nodes (8): getDaily, PuzzleRepository, LocalCrossclimbPuzzleRepository, LocalPatchesPuzzleRepository, LocalPinpointPuzzleRepository, LocalQueensPuzzleRepository, LocalTangoPuzzleRepository, LocalZipPuzzleRepository

### Community 71 - "Tango Generator Module"
Cohesion: 0.22
Nodes (7): _, _extractPotentialConstraints, generate, _generateFullSolution, maxAttempts, _rowMatchesAnyPrevious, TangoGenerator

### Community 72 - "Zip Generator Module"
Cohesion: 0.22
Nodes (8): _, _createDeterministicFallback, generate, _generateEdgeWalls, _generateHamiltonianPath, maxAttempts, _placeCheckpoints, ZipGenerator

### Community 73 - "Illuminate\Database\Schema\Blueprint"
Cohesion: 0.09
Nodes (13): {closure#1}(), {closure#2}(), {closure#3}(), {closure#1}(), {closure#2}(), {closure#1}(), {closure#2}(), {closure#3}() (+5 more)

### Community 74 - "update_prompt_dialog.dart"
Cohesion: 0.07
Nodes (27): bgColor, build, _buildActionButtons, _buildDownloadingView, _buildErrorView, _buildInstallingView, createState, _dismiss (+19 more)

### Community 76 - "badges_screen.dart"
Cohesion: 0.12
Nodes (10): BadgeCategory, BadgesScreen, _buildBadgeCard, _buildCategoryChip, createState, initialCategory, initState, _onlyUnlocked (+2 more)

### Community 77 - "Pinpoint Logic Module"
Cohesion: 0.29
Nodes (6): _, calculateScore, isCorrectGuess, normalize, PinpointLogic, validateLevel

### Community 78 - "update_service.dart"
Cohesion: 0.07
Nodes (25): apkUrl, AppUpdateInfo, changelog, checkForUpdate, compareSemver, currentBuildNumber, currentVersion, _dismissedBuildNumberInSession (+17 more)

### Community 80 - "api_client.dart"
Cohesion: 0.07
Nodes (25): _authToken, _authTokenKey, _cachedBaseUrl, _cachedNickname, checkConnectionAndTimeSync, checkNicknameAvailability, _client, _defaultLiveUrl (+17 more)

### Community 82 - "Win32 Window Module"
Cohesion: 0.50
Nodes (3): Point, x, y

### Community 84 - "completed_game_leaderboard_dialog.dart"
Cohesion: 0.13
Nodes (12): build, CompletedGameLeaderboardDialog, _CompletedGameLeaderboardDialogState, createState, difficulty, durationMs, game, initState (+4 more)

### Community 86 - "base_game.dart"
Cohesion: 0.10
Nodes (20): bestTimeMs, completedAt, difficulty, durationMs, fromJson, GameResult, gamesPlayed, GameType (+12 more)

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

### Community 110 - "main.dart"
Cohesion: 0.15
Nodes (3): build, main, main

### Community 111 - "config"
Cohesion: 0.29
Nodes (7): pestphp/pest-plugin, php-http/discovery, config, allow-plugins, optimize-autoloader, preferred-install, sort-packages

### Community 118 - "psr-4"
Cohesion: 0.40
Nodes (5): autoload, psr-4, App\\, Database\\Factories\\, Database\\Seeders\\

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

## Knowledge Gaps
- **1201 isolated node(s):** `DailyBadge`, `UserBadge`, `label`, `subtitle`, `id` (+1196 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 1537 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **36 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `_` connect `Patches Generator Module` to `Patches Levels Module`, `Crossclimb Generator & Pinpoint Generator`, `Tango Generator Module`, `Puzzle Seed Module`?**
  _High betweenness centrality (0.019) - this node is a cross-community bridge._
- **Are the 37 inferred relationships involving `Kara Kalem Eskiz Defteri Design Language` (e.g. with `mipmap-hdpi/ic_launcher.png` and `mipmap-mdpi/ic_launcher.png`) actually correct?**
  _`Kara Kalem Eskiz Defteri Design Language` has 37 INFERRED edges - model-reasoned connections that need verification._
- **What connects `DailyBadge`, `UserBadge`, `label` to the rest of the system?**
  _1201 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Color Theme & Palette Tokens` be split into smaller, more focused modules?**
  _Cohesion score 0.02247191011235955 - nodes in this community are weakly interconnected._
- **Why does `Win32Window` connect `Win32Window` to `Win32 Window Module`, `Win32 Window Module`, `.MessageHandler`, `Win32 Window & Main`, `Size`, `Win32 Window & Flutter Window`?**
  _High betweenness centrality (0.016) - this node is a cross-community bridge._
- **Should `Queens Screen & Solver UI` be split into smaller, more focused modules?**
  _Cohesion score 0.02531645569620253 - nodes in this community are weakly interconnected._
- **Why does `_` connect `Zip Generator Module` to `zip_logic.dart`, `Crossclimb Generator & Pinpoint Generator`, `Tango Generator Module`, `Puzzle Seed Module`?**
  _High betweenness centrality (0.015) - this node is a cross-community bridge._