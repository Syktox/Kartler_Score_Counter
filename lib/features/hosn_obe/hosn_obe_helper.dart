import 'dart:collection';

import '../../models/game_rules.dart';
import '../../utils/name_utils.dart';
import '../../utils/ordered_map_utils.dart';

class HosnObeHelper {
  const HosnObeHelper._();

  static bool isPlayerNameValid(String playerName, Iterable<String> players) {
    return NameUtils.isUnique(playerName, players);
  }

  static String? winner(Map<String, int> players) {
    return GameRules.lastPlayerWithLives(players);
  }

  static ({Map<String, int> players, String currentPlayer}) addPlayer({
    required Map<String, int> players,
    required String playerName,
    int startingLives = GameRules.defaultHosnObeStartingLives,
  }) {
    return (
      players: Map<String, int>.from(players)
        ..[playerName] = startingLives,
      currentPlayer: playerName,
    );
  }

  static Map<String, int> updateScore({
    required Map<String, int> players,
    required String currentPlayer,
    required int score,
  }) {
    return Map<String, int>.from(players)..[currentPlayer] = score;
  }

  static Map<String, int> resetPlayers(
    Map<String, int> players, {
    int startingLives = GameRules.defaultHosnObeStartingLives,
  }) {
    return Map<String, int>.from(players)
      ..updateAll((key, value) => startingLives);
  }

  static LinkedHashMap<String, int>? reorderPlayers(
    Map<String, int> players,
    int oldIndex,
    int newIndex,
  ) {
    return OrderedMapUtils.reorder(players, oldIndex, newIndex);
  }

  static ({LinkedHashMap<String, int> players, String currentPlayer})
  renamePlayer({
    required Map<String, int> players,
    required String currentPlayer,
    required String oldName,
    required String newName,
  }) {
    final renamedPlayers = OrderedMapUtils.renameSelectedKey(
      values: players,
      selectedKey: currentPlayer,
      oldKey: oldName,
      newKey: newName,
    );

    return (
      players: renamedPlayers.values,
      currentPlayer: renamedPlayers.selectedKey,
    );
  }

  static ({Map<String, int> players, String currentPlayer}) deletePlayer({
    required Map<String, int> players,
    required String currentPlayer,
    required String playerName,
  }) {
    final removedPlayer = OrderedMapUtils.removeSelectedKey(
      values: players,
      selectedKey: currentPlayer,
      key: playerName,
    );

    return (
      players: removedPlayer.values,
      currentPlayer: removedPlayer.selectedKey,
    );
  }
}
