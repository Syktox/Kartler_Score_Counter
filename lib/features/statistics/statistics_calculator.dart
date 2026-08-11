import '../../models/app_mode.dart';
import '../../models/completed_match.dart';
import '../../models/game_session.dart';

class PlayerStatEntry {
  final String playerId;
  final int matches;
  final int wins;
  final int losses;
  final double winRate;

  const PlayerStatEntry({
    required this.playerId,
    required this.matches,
    required this.wins,
    required this.losses,
    required this.winRate,
  });
}

class StatisticsResult {
  final int totalMatches;
  final List<PlayerStatEntry> leaderboard;
  final Map<AppMode, int> matchesPerMode;
  final AppMode? mostPlayedMode;
  final GameSession? lastSession;
  final int totalSessions;
  final int biggestWinMargin;

  const StatisticsResult({
    required this.totalMatches,
    required this.leaderboard,
    required this.matchesPerMode,
    required this.mostPlayedMode,
    required this.lastSession,
    required this.totalSessions,
    required this.biggestWinMargin,
  });
}

/// Berechnet Statistiken ausschließlich aus der gespeicherten Match-History
/// und den Spielabenden – es gibt keine doppelte Datenhaltung.
class StatisticsCalculator {
  const StatisticsCalculator._();

  static StatisticsResult calculate({
    required List<CompletedMatch> matches,
    required List<GameSession> sessions,
  }) {
    final matchesPerPlayer = <String, PlayerStatEntry>{};
    final matchesPerMode = <AppMode, int>{};

    var biggestWinMargin = 0;

    for (final match in matches) {
      if (match.gameType == AppMode.counter) {
        continue;
      }
      matchesPerMode[match.gameType] =
          (matchesPerMode[match.gameType] ?? 0) + 1;

      final sortedScores = match.finalStandings.values.toList()..sort();
      if (sortedScores.length >= 2) {
        final margin = sortedScores.last - sortedScores.first;
        if (margin > biggestWinMargin) {
          biggestWinMargin = margin;
        }
      }

      for (final participantId in match.participantIds) {
        final current =
            matchesPerPlayer[participantId] ??
            const PlayerStatEntry(
              playerId: '',
              matches: 0,
              wins: 0,
              losses: 0,
              winRate: 0,
            );
        final win = match.winnerId == participantId ? 1 : 0;
        final loss =
            match.winnerId != null && match.winnerId != participantId ? 1 : 0;
        final matches = current.matches + 1;
        final wins = current.wins + win;
        final losses = current.losses + loss;

        matchesPerPlayer[participantId] = PlayerStatEntry(
          playerId: participantId,
          matches: matches,
          wins: wins,
          losses: losses,
          winRate: matches == 0 ? 0 : wins / matches,
        );
      }
    }

    final leaderboard = matchesPerPlayer.values.toList()
      ..sort((a, b) {
        final byWins = b.wins.compareTo(a.wins);
        if (byWins != 0) {
          return byWins;
        }
        final byRate = b.winRate.compareTo(a.winRate);
        if (byRate != 0) {
          return byRate;
        }
        return b.matches.compareTo(a.matches);
      });

    AppMode? mostPlayedMode;
    var mostPlayedCount = 0;
    matchesPerMode.forEach((mode, count) {
      if (count > mostPlayedCount) {
        mostPlayedMode = mode;
        mostPlayedCount = count;
      }
    });

    final finished = sessions.where((session) => !session.isActive).toList()
      ..sort((a, b) => b.startTime.compareTo(a.startTime));

    return StatisticsResult(
      totalMatches: matches
          .where((match) => match.gameType != AppMode.counter)
          .length,
      leaderboard: leaderboard,
      matchesPerMode: matchesPerMode,
      mostPlayedMode: mostPlayedMode,
      lastSession: finished.isEmpty ? null : finished.first,
      totalSessions: finished.length,
      biggestWinMargin: biggestWinMargin,
    );
  }

  /// Direkter Vergleich zweier Spieler: gemeinsame Partien und Siege.
  static ({int total, int aWins, int bWins}) headToHead({
    required String playerA,
    required String playerB,
    required List<CompletedMatch> matches,
  }) {
    var total = 0;
    var aWins = 0;
    var bWins = 0;

    for (final match in matches) {
      if (!match.participantIds.contains(playerA) ||
          !match.participantIds.contains(playerB)) {
        continue;
      }
      total += 1;
      if (match.winnerId == playerA) {
        aWins += 1;
      } else if (match.winnerId == playerB) {
        bWins += 1;
      }
    }

    return (total: total, aWins: aWins, bWins: bWins);
  }
}
