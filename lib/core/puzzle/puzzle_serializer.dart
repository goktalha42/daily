import '../../games/crossclimb/crossclimb_models.dart';
import '../../games/patches/patches_models.dart';
import '../../games/pinpoint/pinpoint_models.dart';
import '../../games/queens/queens_models.dart';
import '../../games/tango/tango_models.dart';
import '../../games/zip_path/zip_models.dart';

/// 6 oyun için JSON <-> Level model dönüştürücüleri.
/// Hem sunucu (365 günlük takvim & admin API) hem de istemci (mobil + web) aynı şemayı kullanır.
class PuzzleSerializer {
  PuzzleSerializer._();

  // ---------------------------------------------------------------------------
  // QUEENS (Vezirler)
  // ---------------------------------------------------------------------------
  static Map<String, dynamic> queensToJson(QueensLevel level) {
    return {
      'id': level.id,
      'gridSize': level.gridSize,
      'difficulty': level.difficulty.name,
      'queensPerUnit': level.queensPerUnit,
      'regionMap': level.regionMap,
      'solution': level.solution,
    };
  }

  static QueensLevel queensFromJson(Map<String, dynamic> json, {String? fallbackId}) {
    final diffName = (json['difficulty'] ?? 'kolay').toString();
    final diff = QueensDifficulty.values.firstWhere(
      (d) => d.name == diffName,
      orElse: () => QueensDifficulty.kolay,
    );
    final regionMap = (json['regionMap'] as List<dynamic>)
        .map((row) => (row as List<dynamic>).map((v) => (v as num).toInt()).toList())
        .toList();
    final solution = (json['solution'] as List<dynamic>)
        .map((pair) => (pair as List<dynamic>).map((v) => (v as num).toInt()).toList())
        .toList();

    return QueensLevel(
      id: (json['id'] ?? fallbackId ?? 'queens_daily').toString(),
      gridSize: (json['gridSize'] as num?)?.toInt() ?? regionMap.length,
      difficulty: diff,
      queensPerUnit: (json['queensPerUnit'] as num?)?.toInt() ?? diff.queensPerUnit,
      regionMap: regionMap,
      solution: solution,
    );
  }

  // ---------------------------------------------------------------------------
  // PINPOINT (Kelime İzleri)
  // ---------------------------------------------------------------------------
  static Map<String, dynamic> pinpointToJson(PinpointLevel level) {
    return {
      'id': level.id,
      'categoryHint': level.categoryHint,
      'targetWord': level.targetWord,
      'clues': level.clues,
      'alternativeAnswers': level.alternativeAnswers,
    };
  }

  static PinpointLevel pinpointFromJson(Map<String, dynamic> json, {String? fallbackId}) {
    return PinpointLevel(
      id: (json['id'] ?? fallbackId ?? 'pinpoint_daily').toString(),
      categoryHint: (json['categoryHint'] ?? '').toString(),
      targetWord: (json['targetWord'] ?? '').toString(),
      clues: (json['clues'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(),
      alternativeAnswers: (json['alternativeAnswers'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(),
    );
  }

  // ---------------------------------------------------------------------------
  // CROSSCLIMB (Kelime Tırmanışı)
  // ---------------------------------------------------------------------------
  static Map<String, dynamic> crossclimbToJson(CrossclimbLevel level) {
    return {
      'id': level.id,
      'startWord': level.startWord,
      'endWord': level.endWord,
      'steps': level.steps
          .map((s) => {
                'targetWord': s.targetWord,
                'clue': s.clue,
                'index': s.index,
                'changedIndex': s.changedIndex,
              })
          .toList(),
    };
  }

  static CrossclimbLevel crossclimbFromJson(
    Map<String, dynamic> json, {
    String? fallbackId,
  }) {
    final stepsRaw = json['steps'] as List<dynamic>? ?? const [];
    final steps = <CrossclimbStep>[];
    for (int i = 0; i < stepsRaw.length; i++) {
      final m = stepsRaw[i] as Map<String, dynamic>;
      steps.add(
        CrossclimbStep(
          targetWord: (m['targetWord'] ?? '').toString(),
          clue: (m['clue'] ?? '').toString(),
          index: (m['index'] as num?)?.toInt() ?? i,
          changedIndex: (m['changedIndex'] as num?)?.toInt() ?? 0,
        ),
      );
    }

    return CrossclimbLevel(
      id: (json['id'] ?? fallbackId ?? 'crossclimb_daily').toString(),
      startWord: (json['startWord'] ?? '').toString(),
      endWord: (json['endWord'] ?? '').toString(),
      steps: steps,
    );
  }

  // ---------------------------------------------------------------------------
  // TANGO (Güneş & Ay)
  // ---------------------------------------------------------------------------
  static int _symbolToInt(TangoSymbol s) => switch (s) {
        TangoSymbol.empty => 0,
        TangoSymbol.sun => 1,
        TangoSymbol.moon => 2,
      };

  static TangoSymbol _parseSymbol(dynamic v) {
    if (v is num) {
      return switch (v.toInt()) {
        1 => TangoSymbol.sun,
        2 => TangoSymbol.moon,
        _ => TangoSymbol.empty,
      };
    }
    return switch (v.toString().toLowerCase()) {
      'sun' || '1' => TangoSymbol.sun,
      'moon' || '2' => TangoSymbol.moon,
      _ => TangoSymbol.empty,
    };
  }

  static Map<String, dynamic> tangoToJson(TangoLevel level) {
    return {
      'id': level.id,
      'gridSize': level.gridSize,
      'difficulty': level.difficulty?.name,
      'initialGrid': level.initialGrid
          .map((row) => row.map(_symbolToInt).toList())
          .toList(),
      'constraints': level.constraints
          .map((c) => {
                'r1': c.r1,
                'c1': c.c1,
                'r2': c.r2,
                'c2': c.c2,
                'type': c.type.name,
              })
          .toList(),
      'solution': level.solution
          ?.map((row) => row.map(_symbolToInt).toList())
          .toList(),
    };
  }

  static TangoLevel tangoFromJson(Map<String, dynamic> json, {String? fallbackId}) {
    final initialGrid = (json['initialGrid'] as List<dynamic>)
        .map((row) => (row as List<dynamic>).map(_parseSymbol).toList())
        .toList();

    final constraints = (json['constraints'] as List<dynamic>? ?? const [])
        .map((raw) {
          final c = raw as Map<String, dynamic>;
          final typeStr = (c['type'] ?? 'equal').toString();
          return TangoConstraint(
            r1: (c['r1'] as num).toInt(),
            c1: (c['c1'] as num).toInt(),
            r2: (c['r2'] as num).toInt(),
            c2: (c['c2'] as num).toInt(),
            type: typeStr == 'opposite'
                ? ConstraintType.opposite
                : ConstraintType.equal,
          );
        })
        .toList();

    final solRaw = json['solution'] as List<dynamic>?;
    final solution = solRaw
        ?.map((row) => (row as List<dynamic>).map(_parseSymbol).toList())
        .toList();

    final diffName = json['difficulty']?.toString();
    TangoDifficulty? diff;
    if (diffName != null) {
      for (final d in TangoDifficulty.values) {
        if (d.name == diffName) {
          diff = d;
          break;
        }
      }
    }

    return TangoLevel(
      id: (json['id'] ?? fallbackId ?? 'tango_daily').toString(),
      gridSize: (json['gridSize'] as num?)?.toInt() ?? initialGrid.length,
      initialGrid: initialGrid,
      constraints: constraints,
      solution: solution,
      difficulty: diff,
    );
  }

  // ---------------------------------------------------------------------------
  // ZIP PATH (Sayı Yolu)
  // ---------------------------------------------------------------------------
  static Map<String, dynamic> zipToJson(ZipLevel level) {
    final sortedPoints = level.numberPoints.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    return {
      'id': level.id,
      'gridSize': level.gridSize,
      'difficulty': level.difficulty?.name,
      'numberPoints': sortedPoints
          .map((e) => {
                'row': e.key.row,
                'col': e.key.col,
                'num': e.value,
              })
          .toList(),
      'walls': level.walls.map((p) => {'row': p.row, 'col': p.col}).toList(),
      'edgeWalls': level.edgeWalls.map((w) => w.toJson()).toList(),
      'solutionPath': level.solutionPath
          ?.map((p) => {'row': p.row, 'col': p.col})
          .toList(),
    };
  }

  static ZipLevel zipFromJson(Map<String, dynamic> json, {String? fallbackId}) {
    final numberPoints = <Point, int>{};
    for (final raw in (json['numberPoints'] as List<dynamic>? ?? const [])) {
      final m = raw as Map<String, dynamic>;
      numberPoints[Point((m['row'] as num).toInt(), (m['col'] as num).toInt())] =
          (m['num'] as num).toInt();
    }

    final walls = <Point>{};
    for (final raw in (json['walls'] as List<dynamic>? ?? const [])) {
      final m = raw as Map<String, dynamic>;
      walls.add(Point((m['row'] as num).toInt(), (m['col'] as num).toInt()));
    }

    final edgeWalls = <ZipEdgeWall>{};
    for (final raw in (json['edgeWalls'] as List<dynamic>? ?? const [])) {
      edgeWalls.add(ZipEdgeWall.fromJson(raw as Map<String, dynamic>));
    }

    final solRaw = json['solutionPath'] as List<dynamic>?;
    final solutionPath = solRaw
        ?.map((raw) {
          final m = raw as Map<String, dynamic>;
          return Point((m['row'] as num).toInt(), (m['col'] as num).toInt());
        })
        .toList();

    final diffName = json['difficulty']?.toString();
    ZipDifficulty? diff;
    if (diffName != null) {
      for (final d in ZipDifficulty.values) {
        if (d.name == diffName) {
          diff = d;
          break;
        }
      }
    }

    return ZipLevel(
      id: (json['id'] ?? fallbackId ?? 'zip_daily').toString(),
      gridSize: (json['gridSize'] as num?)?.toInt() ?? 5,
      numberPoints: numberPoints,
      walls: walls,
      edgeWalls: edgeWalls,
      solutionPath: solutionPath,
      difficulty: diff,
    );
  }

  // ---------------------------------------------------------------------------
  // PATCHES (Alan Bölme)
  // ---------------------------------------------------------------------------
  static Map<String, dynamic> patchesToJson(PatchesLevel level) {
    return {
      'id': level.id,
      'gridSize': level.gridSize,
      'difficulty': level.difficulty.name,
      'clues': level.clues
          .map((c) => {
                'row': c.row,
                'col': c.col,
                'targetArea': c.targetArea,
                'shapeType': c.shapeType.name,
              })
          .toList(),
      'solution': level.solution
          ?.map((r) => {
                'topRow': r.topRow,
                'leftCol': r.leftCol,
                'bottomRow': r.bottomRow,
                'rightCol': r.rightCol,
                'colorIndex': r.colorIndex,
              })
          .toList(),
    };
  }

  static PatchesLevel patchesFromJson(
    Map<String, dynamic> json, {
    String? fallbackId,
  }) {
    final diffName = (json['difficulty'] ?? 'orta').toString();
    final diff = PatchesDifficulty.values.firstWhere(
      (d) => d.name == diffName,
      orElse: () => PatchesDifficulty.orta,
    );

    final clues = (json['clues'] as List<dynamic>? ?? const []).map((raw) {
      final m = raw as Map<String, dynamic>;
      final shapeName = (m['shapeType'] ?? 'any').toString();
      final shape = PatchShapeType.values.firstWhere(
        (s) => s.name == shapeName,
        orElse: () => PatchShapeType.any,
      );
      return PatchesClue(
        row: (m['row'] as num).toInt(),
        col: (m['col'] as num).toInt(),
        targetArea: (m['targetArea'] as num).toInt(),
        shapeType: shape,
      );
    }).toList();

    final solRaw = json['solution'] as List<dynamic>?;
    final solution = solRaw?.map((raw) {
      final m = raw as Map<String, dynamic>;
      return PatchRect(
        topRow: (m['topRow'] as num).toInt(),
        leftCol: (m['leftCol'] as num).toInt(),
        bottomRow: (m['bottomRow'] as num).toInt(),
        rightCol: (m['rightCol'] as num).toInt(),
        colorIndex: (m['colorIndex'] as num?)?.toInt() ?? 0,
      );
    }).toList();

    return PatchesLevel(
      id: (json['id'] ?? fallbackId ?? 'patches_daily').toString(),
      gridSize: (json['gridSize'] as num?)?.toInt() ?? diff.gridSize,
      clues: clues,
      solution: solution,
      difficulty: diff,
    );
  }
}

