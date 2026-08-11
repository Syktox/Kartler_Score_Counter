import 'dart:async';
import 'dart:collection';

import '../../commands/callback_command.dart';
import '../../core/haptics_service.dart';
import '../../models/watten_game.dart';
import '../../models/watten_side.dart';
import '../../persistence/repositories/watten_repository.dart';
import '../feature_controller.dart';
import '../settings/settings_controller.dart';
import 'watten_helper.dart';

/// State und Geschäftslogik für Watten.
class WattenController extends FeatureController {
  WattenController({
    required WattenRepository repository,
    required SettingsController settings,
    required HapticsService haptics,
  }) : _repository = repository,
       _settings = settings,
       _haptics = haptics;

  final WattenRepository _repository;
  final SettingsController _settings;
  final HapticsService _haptics;

  Map<String, WattenGame> games = Map<String, WattenGame>.from(
    WattenRepository.defaultGames,
  );
  String currentGame = WattenRepository.defaultCurrentGame;
  WattenSide selectedSide = WattenSide.me;
  DateTime roundStartedAt = DateTime.now();

  bool get tableMode => _settings.wattenTableMode;
  int get winningScore => _settings.ruleProfile.wattenWinningScore;

  @override
  Future<void> load() async {
    final data = await _repository.load();
    games = data.games;
    currentGame = data.currentGame;
    roundStartedAt = DateTime.now();
    isLoading = false;
  }

  String? winner([WattenGame? game]) {
    return WattenHelper.winner(
      game ?? games[currentGame]!,
      winningScore: winningScore,
    );
  }

  int sideScore(WattenSide side) {
    return WattenHelper.sideScore(games[currentGame]!, side);
  }

  void selectGame(String gameName) {
    if (currentGame == gameName || !games.containsKey(gameName)) {
      return;
    }
    _mutate(() => currentGame = gameName);
  }

  void selectSide(WattenSide side) {
    if (selectedSide == side) {
      return;
    }
    _mutate(() => selectedSide = side);
  }

  void changeScore(int delta) {
    final game = games[currentGame]!;
    final oldValue = WattenHelper.sideScore(game, selectedSide);
    if (oldValue + delta < 0) {
      return;
    }
    final wasWinner = winner() != null;
    _pushUndoable(
      () => _applySideScore(selectedSide, delta),
      revert: () => _applySideScore(selectedSide, -delta),
    );
    if (!wasWinner && winner() != null) {
      unawaited(_haptics.heavy());
    } else {
      unawaited(_haptics.light());
    }
  }

  void resetSelectedSide() {
    final value = sideScore(selectedSide);
    if (value == 0) {
      return;
    }
    final wasWinner = winner() != null;
    _pushUndoable(
      () => _applySideScore(selectedSide, -value),
      revert: () => _applySideScore(selectedSide, value),
    );
    if (!wasWinner && winner() != null) {
      unawaited(_haptics.heavy());
    } else {
      unawaited(_haptics.light());
    }
  }

  /// Setzt beide Seiten auf 0 (für „Partie abschließen“).
  void resetBoard() {
    final game = games[currentGame]!;
    if (game.me == 0 && game.you == 0) {
      return;
    }
    _pushUndoable(
      () => _applyBoardReset(0, 0),
      revert: () => _applyBoardReset(game.me, game.you),
    );
    roundStartedAt = DateTime.now();
    unawaited(_haptics.light());
  }

  void _applySideScore(WattenSide side, int delta) {
    games = Map<String, WattenGame>.from(games)
      ..[currentGame] = WattenHelper.updateSideScore(
        game: games[currentGame]!,
        side: side,
        delta: delta,
      );
    notifyListeners();
    unawaited(_persist());
  }

  void _applyBoardReset(int me, int you) {
    games = Map<String, WattenGame>.from(games)
      ..[currentGame] = WattenGame(me: me, you: you);
    notifyListeners();
    unawaited(_persist());
  }

  void addGame(String gameName) {
    final result = WattenHelper.addGame(games: games, gameName: gameName);
    final oldCurrent = currentGame;
    final oldSide = selectedSide;
    _pushUndoable(() {
      games = result.games;
      currentGame = result.currentGame;
      selectedSide = result.selectedSide;
    }, revert: () {
      games = LinkedHashMap<String, WattenGame>.from(games)
        ..remove(gameName);
      currentGame = oldCurrent;
      selectedSide = oldSide;
    });
    unawaited(_haptics.light());
  }

  void renameGame(String oldName, String newName) {
    final renamed = WattenHelper.renameGame(
      games: games,
      oldName: oldName,
      newName: newName,
    );
    final oldCurrent = currentGame;
    _pushUndoable(() {
      games = renamed;
      if (currentGame == oldName) {
        currentGame = newName;
      }
    }, revert: () {
      games = WattenHelper.renameGame(
        games: games,
        oldName: newName,
        newName: oldName,
      );
      currentGame = oldCurrent == oldName ? oldName : currentGame;
    });
    unawaited(_haptics.light());
  }

  void deleteGame(String gameName) {
    if (games.length <= 1) {
      return;
    }
    final result = WattenHelper.deleteGame(
      games: games,
      currentGame: currentGame,
      gameName: gameName,
    );
    final removed = games[gameName]!;
    _pushUndoable(() {
      games = result.games;
      currentGame = result.currentGame;
    }, revert: () {
      final entries = games.entries.toList();
      games = LinkedHashMap<String, WattenGame>.fromEntries([
        ...entries.takeWhile((entry) => entry.key != gameName),
        MapEntry(gameName, removed),
        ...entries.skipWhile((entry) => entry.key != gameName),
      ]);
      currentGame = gameName;
    });
    unawaited(_haptics.light());
  }

  void reorderGames(int oldIndex, int newIndex) {
    final reordered = WattenHelper.reorderGames(games, oldIndex, newIndex);
    if (reordered == null) {
      return;
    }
    final original = LinkedHashMap<String, WattenGame>.from(games);
    _pushUndoable(() => games = reordered, revert: () => games = original);
    unawaited(_haptics.light());
  }

  void setTableMode(bool enabled) {
    _settings.setWattenTableMode(enabled);
  }

  void _mutate(void Function() change) {
    change();
    notifyListeners();
    unawaited(_persist());
  }

  void _pushUndoable(void Function() apply, {void Function()? revert}) {
    history.execute(
      CallbackCommand(applyChange: apply, revertChange: revert ?? apply),
    );
  }

  Future<void> _persist() {
    return _repository.save(games: games, currentGame: currentGame);
  }
}
