import 'watten_game.dart';

class GameRules {
  static const int wattenWinningScore = 11;
  static const int mulatschakStartingScore = 21;
  static const int hosnObeStartingLives = 4;

  const GameRules._();

  static String? wattenWinner(WattenGame game) {
    if (game.me >= wattenWinningScore && game.me > game.you) {
      return 'Me';
    }
    if (game.you >= wattenWinningScore && game.you > game.me) {
      return 'You';
    }
    return null;
  }

  static String? firstZeroScoreWinner(Map<String, int> players) {
    for (final entry in players.entries) {
      if (entry.value == 0) {
        return entry.key;
      }
    }
    return null;
  }

  static String? lastPlayerWithLives(Map<String, int> players) {
    final alivePlayers = players.entries
        .where((entry) => entry.value > 0)
        .toList(growable: false);
    return alivePlayers.length == 1 ? alivePlayers.single.key : null;
  }

  static int clampAtZero(int score) {
    return score < 0 ? 0 : score;
  }

  static int applyResetLoop({
    required int score,
    required int triggerPoints,
    required int resetPoints,
  }) {
    final resetDifference = triggerPoints - resetPoints;
    if (resetDifference <= 0) {
      return score;
    }

    var adjustedScore = score;
    while (adjustedScore >= triggerPoints) {
      adjustedScore -= resetDifference;
    }
    return adjustedScore;
  }
}
