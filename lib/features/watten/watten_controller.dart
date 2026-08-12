import 'dart:async';

import '../../commands/callback_command.dart';
import '../../core/haptics_service.dart';
import '../../models/watten_game.dart';
import '../../models/watten_history_entry.dart';
import '../../models/watten_side.dart';
import '../../persistence/repositories/watten_repository.dart';
import '../../utils/history_utils.dart';
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
  List<String> meTeam = const [];
  List<String> youTeam = const [];
  List<String> historyEntries = const [];
  DateTime roundStartedAt = DateTime.now();

  bool get tableMode => _settings.wattenTableMode;
  bool get historyEnabled => _settings.wattenHistoryEnabled;
  int get winningScore => _settings.ruleProfile.wattenWinningScore;

  @override
  Future<void> load() async {
    final data = await _repository.load();
    games = data.games;
    currentGame = data.currentGame;
    meTeam = data.meTeam;
    youTeam = data.youTeam;
    historyEntries = data.history;
    roundStartedAt = DateTime.now();
    isLoading = false;
  }

  /// Legt fest, welche Spieler im Team „Wir“ bzw. „Die“ spielen.
  void setTeams({required List<String> me, required List<String> you}) {
    _mutate(() {
      meTeam = List.unmodifiable(me);
      youTeam = List.unmodifiable(you);
    });
    unawaited(_haptics.light());
  }

  /// Entfernt einen Spieler aus beiden Teams (Spieler-Löschung).
  void removePlayerFromTeams(String playerId) {
    if (!meTeam.contains(playerId) && !youTeam.contains(playerId)) {
      return;
    }
    _mutate(() {
      meTeam = meTeam.where((id) => id != playerId).toList(growable: false);
      youTeam = youTeam.where((id) => id != playerId).toList(growable: false);
    });
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

  void selectSide(WattenSide side) {
    if (selectedSide == side) {
      return;
    }
    _mutate(() => selectedSide = side);
  }

  void changeScore(int delta) {
    final game = games[currentGame]!;
    final side = selectedSide;
    final oldValue = WattenHelper.sideScore(game, side);
    if (oldValue + delta < 0) {
      return;
    }
    final wasWinner = winner() != null;
    final changeTime = DateTime.now();
    _pushUndoable(
      () => _applySideScore(side, delta, changeTime, recordEntry: true),
      revert: () => _applySideScore(
        side,
        -delta,
        changeTime,
        recordEntry: false,
        historyDelta: delta,
      ),
    );
    if (!wasWinner && winner() != null) {
      unawaited(_haptics.heavy());
    } else {
      unawaited(_haptics.light());
    }
  }

  void resetSelectedSide() {
    final side = selectedSide;
    final value = sideScore(side);
    if (value == 0) {
      return;
    }
    final wasWinner = winner() != null;
    final changeTime = DateTime.now();
    _pushUndoable(
      () => _applySideScore(side, -value, changeTime, recordEntry: true),
      revert: () => _applySideScore(
        side,
        value,
        changeTime,
        recordEntry: false,
        historyDelta: -value,
      ),
    );
    if (!wasWinner && winner() != null) {
      unawaited(_haptics.heavy());
    } else {
      unawaited(_haptics.light());
    }
  }

  /// Setzt beide Seiten auf 0 (für „Partie abschließen“).
  void resetBoard({bool clearHistory = false}) {
    final game = games[currentGame]!;
    if (game.me == 0 &&
        game.you == 0 &&
        (!clearHistory || historyEntries.isEmpty)) {
      return;
    }
    final oldHistory = List<String>.from(historyEntries);
    _pushUndoable(
      () => _applyBoardReset(0, 0, clearHistory: clearHistory),
      revert: () =>
          _applyBoardReset(game.me, game.you, historyEntries: oldHistory),
    );
    roundStartedAt = DateTime.now();
    unawaited(_haptics.light());
  }

  void _applySideScore(
    WattenSide side,
    int delta,
    DateTime changeTime, {
    required bool recordEntry,
    int? historyDelta,
  }) {
    games = Map<String, WattenGame>.from(games)
      ..[currentGame] = WattenHelper.updateSideScore(
        game: games[currentGame]!,
        side: side,
        delta: delta,
      );
    final entry = WattenHistoryEntry(
      time: HistoryUtils.formatTime(changeTime),
      side: side,
      points: historyDelta ?? delta,
    ).encode();
    if (recordEntry && historyEnabled) {
      historyEntries = [...historyEntries, entry];
    } else if (!recordEntry) {
      final entries = List<String>.from(historyEntries);
      entries.remove(entry);
      historyEntries = entries;
    }
    notifyListeners();
    unawaited(_persist());
  }

  void _applyBoardReset(
    int me,
    int you, {
    bool clearHistory = false,
    List<String>? historyEntries,
  }) {
    games = Map<String, WattenGame>.from(games)
      ..[currentGame] = WattenGame(me: me, you: you);
    if (clearHistory) {
      this.historyEntries = const [];
    } else if (historyEntries != null) {
      this.historyEntries = historyEntries;
    }
    notifyListeners();
    unawaited(_persist());
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
    return _repository.save(
      games: games,
      currentGame: currentGame,
      meTeam: meTeam,
      youTeam: youTeam,
      history: historyEntries,
    );
  }
}
