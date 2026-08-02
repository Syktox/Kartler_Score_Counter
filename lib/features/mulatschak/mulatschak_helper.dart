import 'dart:collection';

import '../../models/game_rules.dart';
import '../../models/mulatschak_history_entry.dart';
import '../../utils/history_utils.dart';
import '../../utils/name_utils.dart';
import '../../utils/ordered_map_utils.dart';

class MulatschakHelper {
  const MulatschakHelper._();

  static bool isPlayerNameValid(String playerName, Iterable<String> players) {
    return NameUtils.isUnique(playerName, players);
  }

  static String? winner(Map<String, int> players) {
    return GameRules.firstZeroScoreWinner(players);
  }

  static ({
    Map<String, int> players,
    String currentPlayer,
    Set<String> roundPlayers,
  })
  addPlayer({
    required Map<String, int> players,
    required Set<String> roundPlayers,
    required String playerName,
  }) {
    return (
      players: Map<String, int>.from(players)
        ..[playerName] = GameRules.mulatschakStartingScore,
      currentPlayer: playerName,
      roundPlayers: Set<String>.from(roundPlayers)..remove(playerName),
    );
  }

  static int nextScore({
    required int currentValue,
    required int baseDelta,
    required int multiplier,
    required bool muleqackEnabled,
    required int triggerPoints,
    required int resetPoints,
  }) {
    final delta = baseDelta * multiplier;
    final clampedScore = GameRules.clampAtZero(currentValue + delta);

    return muleqackEnabled
        ? applyMuleqackReset(
            score: clampedScore,
            triggerPoints: triggerPoints,
            resetPoints: resetPoints,
          )
        : clampedScore;
  }

  static int applyMuleqackReset({
    required int score,
    required int triggerPoints,
    required int resetPoints,
  }) {
    return GameRules.applyResetLoop(
      score: score,
      triggerPoints: triggerPoints,
      resetPoints: resetPoints,
    );
  }

  static LinkedHashMap<String, int>? reorderPlayers(
    Map<String, int> players,
    int oldIndex,
    int newIndex,
  ) {
    return OrderedMapUtils.reorder(players, oldIndex, newIndex);
  }

  static ({
    LinkedHashMap<String, int> players,
    String currentPlayer,
    Set<String> roundPlayers,
  })
  renamePlayer({
    required Map<String, int> players,
    required String currentPlayer,
    required Set<String> roundPlayers,
    required String oldName,
    required String newName,
  }) {
    final nextRoundPlayers = Set<String>.from(roundPlayers);
    if (nextRoundPlayers.remove(oldName)) {
      nextRoundPlayers.add(newName);
    }

    return (
      players: OrderedMapUtils.renameKey(players, oldName, newName),
      currentPlayer: currentPlayer == oldName ? newName : currentPlayer,
      roundPlayers: nextRoundPlayers,
    );
  }

  static ({
    Map<String, int> players,
    String currentPlayer,
    Set<String> roundPlayers,
    int historyRound,
  })
  deletePlayer({
    required Map<String, int> players,
    required String currentPlayer,
    required Set<String> roundPlayers,
    required int historyRound,
    required String playerName,
  }) {
    final nextPlayers = Map<String, int>.from(players)..remove(playerName);
    var nextRoundPlayers = Set<String>.from(roundPlayers)..remove(playerName);
    var nextHistoryRound = historyRound;

    if (nextRoundPlayers.length >= nextPlayers.length) {
      nextHistoryRound += 1;
      nextRoundPlayers = {};
    }

    return (
      players: nextPlayers,
      currentPlayer: currentPlayer == playerName
          ? nextPlayers.keys.first
          : currentPlayer,
      roundPlayers: nextRoundPlayers,
      historyRound: nextHistoryRound,
    );
  }

  static ({List<String> history, Set<String> roundPlayers, int historyRound})
  recordHistory({
    required bool enabled,
    required List<String> history,
    required Map<String, int> players,
    required Set<String> roundPlayers,
    required int historyRound,
    required String playerName,
    required int points,
  }) {
    if (!enabled || points == 0) {
      return (
        history: history,
        roundPlayers: roundPlayers,
        historyRound: historyRound,
      );
    }

    var nextRoundPlayers = Set<String>.from(roundPlayers)..add(playerName);
    var nextHistoryRound = historyRound;

    if (nextRoundPlayers.length >= players.length) {
      nextHistoryRound += 1;
      nextRoundPlayers = {};
    }

    return (
      history: [
        ...history,
        MulatschakHistoryEntry(
          round: historyRound,
          time: HistoryUtils.formatTime(DateTime.now()),
          playerName: playerName,
          points: points,
        ).encode(),
      ],
      roundPlayers: nextRoundPlayers,
      historyRound: nextHistoryRound,
    );
  }
}
