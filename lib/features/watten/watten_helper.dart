import 'dart:collection';

import '../../models/game_rules.dart';
import '../../models/watten_game.dart';
import '../../models/watten_side.dart';
import '../../utils/name_utils.dart';
import '../../utils/ordered_map_utils.dart';

class WattenHelper {
  const WattenHelper._();

  static bool isGameNameValid(String gameName, Iterable<String> gameNames) {
    return NameUtils.isUnique(gameName, gameNames);
  }

  static String? winner(WattenGame game, {int winningScore = 11}) {
    return GameRules.wattenWinner(game, winningScore: winningScore);
  }

  static ({
    Map<String, WattenGame> games,
    String currentGame,
    WattenSide selectedSide,
  })
  addGame({required Map<String, WattenGame> games, required String gameName}) {
    return (
      games: Map<String, WattenGame>.from(games)
        ..[gameName] = const WattenGame(me: 0, you: 0),
      currentGame: gameName,
      selectedSide: WattenSide.me,
    );
  }

  static ({Map<String, WattenGame> games, String currentGame}) deleteGame({
    required Map<String, WattenGame> games,
    required String currentGame,
    required String gameName,
  }) {
    final nextGames = Map<String, WattenGame>.from(games)..remove(gameName);

    return (
      games: nextGames,
      currentGame: currentGame == gameName ? nextGames.keys.first : currentGame,
    );
  }

  static LinkedHashMap<String, WattenGame> renameGame({
    required Map<String, WattenGame> games,
    required String oldName,
    required String newName,
  }) {
    return OrderedMapUtils.renameKey(games, oldName, newName);
  }

  static LinkedHashMap<String, WattenGame>? reorderGames(
    Map<String, WattenGame> games,
    int oldIndex,
    int newIndex,
  ) {
    return OrderedMapUtils.reorder(games, oldIndex, newIndex);
  }

  static WattenGame updateSideScore({
    required WattenGame game,
    required WattenSide side,
    required int delta,
  }) {
    final currentValue = side == WattenSide.me ? game.me : game.you;
    final nextValue = currentValue + delta;

    return side == WattenSide.me
        ? game.copyWith(me: nextValue)
        : game.copyWith(you: nextValue);
  }

  static WattenGame resetSideScore({
    required WattenGame game,
    required WattenSide side,
  }) {
    return side == WattenSide.me ? game.copyWith(me: 0) : game.copyWith(you: 0);
  }

  static int sideScore(WattenGame game, WattenSide side) {
    return side == WattenSide.me ? game.me : game.you;
  }
}
