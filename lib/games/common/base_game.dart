import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

enum GameType {
  queens,
  pinpoint,
  crossclimb,
  tango,
  zipPath,
  patches,
}

extension GameTypeExtension on GameType {
  String get id {
    switch (this) {
      case GameType.queens:
        return 'queens';
      case GameType.pinpoint:
        return 'pinpoint';
      case GameType.crossclimb:
        return 'crossclimb';
      case GameType.tango:
        return 'tango';
      case GameType.zipPath:
        return 'zipPath';
      case GameType.patches:
        return 'patches';
    }
  }

  String get title {
    switch (this) {
      case GameType.queens:
        return 'Vezirler';
      case GameType.pinpoint:
        return 'Kelime İzleri';
      case GameType.crossclimb:
        return 'Kelime Tırmanışı';
      case GameType.tango:
        return 'Güneş & Ay';
      case GameType.zipPath:
        return 'Sayı Yolu';
      case GameType.patches:
        return 'Alan Bölme';
    }
  }

  String get englishTitle {
    switch (this) {
      case GameType.queens:
        return 'Queens';
      case GameType.pinpoint:
        return 'Pinpoint';
      case GameType.crossclimb:
        return 'Crossclimb';
      case GameType.tango:
        return 'Tango';
      case GameType.zipPath:
        return 'Zip Path';
      case GameType.patches:
        return 'Patches';
    }
  }

  String get description {
    switch (this) {
      case GameType.queens:
        return 'Her satır, sütun ve renk bölgesine birbirine temas etmeyecek 1 vezir yerleştir.';
      case GameType.pinpoint:
        return 'Verilen ipuçlarından yola çıkarak gizli anahtar kelimeyi tahmin et.';
      case GameType.crossclimb:
        return 'Harfleri sırayla değiştirip ipuçlarını çözerek zirve kelimesine ulaş.';
      case GameType.tango:
        return 'Izgarayı Güneş ve Ay ile doldur. Yan yana 3 aynı sembol koyma!';
      case GameType.zipPath:
        return 'Sayıları sırayla kesişmeyen tek bir yol ile birbirine bağla.';
      case GameType.patches:
        return 'Izgarayı, her biri tam bir sayı içeren ve alanı o sayıya eşit dikdörtgenlere böl.';
    }
  }

  IconData get icon {
    switch (this) {
      case GameType.queens:
        return Icons.castle_rounded;
      case GameType.pinpoint:
        return Icons.search_rounded;
      case GameType.crossclimb:
        return Icons.stairs_rounded;
      case GameType.tango:
        return Icons.wb_sunny_rounded;
      case GameType.zipPath:
        return Icons.alt_route_rounded;
      case GameType.patches:
        return Icons.dashboard_customize_rounded;
    }
  }

  Color get color {
    switch (this) {
      case GameType.queens:
        return AppColors.queensGame;
      case GameType.pinpoint:
        return AppColors.pinpointGame;
      case GameType.crossclimb:
        return AppColors.crossclimbGame;
      case GameType.tango:
        return AppColors.tangoGame;
      case GameType.zipPath:
        return AppColors.zipGame;
      case GameType.patches:
        return AppColors.patchesGame;
    }
  }

  LinearGradient get gradient {
    switch (this) {
      case GameType.queens:
        return AppColors.queensGradient;
      case GameType.pinpoint:
        return AppColors.pinpointGradient;
      case GameType.crossclimb:
        return AppColors.crossclimbGradient;
      case GameType.tango:
        return AppColors.tangoGradient;
      case GameType.zipPath:
        return AppColors.zipGradient;
      case GameType.patches:
        return AppColors.patchesGradient;
    }
  }

  String get categoryTag {
    switch (this) {
      case GameType.queens:
        return 'MANTIK & IZGARA';
      case GameType.pinpoint:
        return 'KELİME TAHMİNİ';
      case GameType.crossclimb:
        return 'KELİME DİZİLİMİ';
      case GameType.tango:
        return 'İKİLİ MANTIK';
      case GameType.zipPath:
        return 'DESEN BAĞLANTI';
      case GameType.patches:
        return 'GEOMETRİ & ALAN';
    }
  }
}

enum LeaderboardTimeframe {
  weekly,
  monthly,
  allTime,
}

extension LeaderboardTimeframeExtension on LeaderboardTimeframe {
  String get label {
    switch (this) {
      case LeaderboardTimeframe.weekly:
        return 'Haftalık';
      case LeaderboardTimeframe.monthly:
        return 'Aylık';
      case LeaderboardTimeframe.allTime:
        return 'Genel';
    }
  }
}

class GameResult {
  final String id;
  final GameType gameType;
  final String levelId;
  final String userId;
  final String userName;
  final int durationMs;
  final int moveCount;
  final int score;
  final DateTime completedAt;

  GameResult({
    required this.id,
    required this.gameType,
    required this.levelId,
    required this.userId,
    required this.userName,
    required this.durationMs,
    required this.moveCount,
    required this.score,
    required this.completedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'gameType': gameType.id,
      'levelId': levelId,
      'userId': userId,
      'userName': userName,
      'durationMs': durationMs,
      'moveCount': moveCount,
      'score': score,
      'completedAt': completedAt.toIso8601String(),
    };
  }

  factory GameResult.fromJson(Map<String, dynamic> json) {
    return GameResult(
      id: json['id'],
      gameType: GameType.values.firstWhere((e) => e.id == json['gameType']),
      levelId: json['levelId'],
      userId: json['userId'],
      userName: json['userName'],
      durationMs: json['durationMs'],
      moveCount: json['moveCount'],
      score: json['score'],
      completedAt: DateTime.parse(json['completedAt']),
    );
  }
}

class LeaderboardEntry {
  final int rank;
  final String userId;
  final String userName;
  final int totalScore;
  final int bestTimeMs;
  final int gamesPlayed;

  LeaderboardEntry({
    required this.rank,
    required this.userId,
    required this.userName,
    required this.totalScore,
    required this.bestTimeMs,
    required this.gamesPlayed,
  });
}
