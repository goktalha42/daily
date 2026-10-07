class PinpointLevel {
  final String id;
  final String categoryHint;
  final String targetWord; // The secret target word/concept to guess
  final List<String> clues; // List of 5 progressive clues
  final List<String> alternativeAnswers;

  PinpointLevel({
    required this.id,
    required this.categoryHint,
    required this.targetWord,
    required this.clues,
    this.alternativeAnswers = const [],
  });
}

