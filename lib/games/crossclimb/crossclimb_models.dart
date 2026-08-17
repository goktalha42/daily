class CrossclimbStep {
  final String targetWord; // Word to be guessed for this step
  final String clue;       // Trivia clue for this word
  final int index;
  final int changedIndex;  // Which letter position changed from the previous word

  CrossclimbStep({
    required this.targetWord,
    required this.clue,
    required this.index,
    required this.changedIndex,
  });
}

class CrossclimbLevel {
  final String id;
  final String startWord;
  final String endWord;
  final List<CrossclimbStep> steps;

  CrossclimbLevel({
    required this.id,
    required this.startWord,
    required this.endWord,
    required this.steps,
  });
}
