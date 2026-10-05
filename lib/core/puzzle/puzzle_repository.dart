/// Bulmaca kaynağı arayüzü.
///
/// Aşama A (yerel): cihazdaki jeneratör (`Local*PuzzleRepository`).
/// Aşama B (VDS): REST API (`Remote*PuzzleRepository`).
/// Arayüz sabit kaldığı için oyun ekranları geçişten etkilenmez.
abstract class PuzzleRepository<T> {
  /// [dateId]: UTC gün kimliği, `YYYY-MM-DD`.
  Future<T> getDaily(String dateId);
}
