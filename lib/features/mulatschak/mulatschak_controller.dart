import 'dart:async';

import '../../commands/callback_command.dart';
import '../../commands/undoable_command.dart';
import '../../core/haptics_service.dart';
import '../../models/mulatschak_history_entry.dart';
import '../../models/rule_profile.dart';
import '../../persistence/repositories/mulatschak_repository.dart';
import '../../utils/history_utils.dart';
import '../feature_controller.dart';
import '../players/players_controller.dart';
import '../settings/settings_controller.dart';
import 'mulatschak_helper.dart';

/// State und Geschäftslogik für Mulatschak.
///
/// Punkteänderungen laufen über ein Command-System mit Undo/Redo;
/// Rundenverlauf und Muleqack-Reset sind in [MulatschakHelper] gekapselt.
class MulatschakController extends FeatureController {
  MulatschakController({
    required MulatschakRepository repository,
    required SettingsController settings,
    required PlayersController players,
    required HapticsService haptics,
  }) : _repository = repository,
       _settings = settings,
       _players = players,
       _haptics = haptics;

  final MulatschakRepository _repository;
  final SettingsController _settings;
  final PlayersController _players;
  final HapticsService _haptics;

  Map<String, int> lineup = {};
  String currentPlayerId = '';
  int multiplier = MulatschakRepository.defaultMultiplier;
  List<String> historyEntries = [];
  int historyRound = MulatschakRepository.defaultHistoryRound;
  Set<String> roundPlayerIds = {};
  DateTime roundStartedAt = DateTime.now();

  bool get historyEnabled => _settings.mulatschakHistoryEnabled;
  RuleProfile get _profile => _settings.ruleProfile;

  @override
  Future<void> load() async {
    final data = await _repository.load();
    lineup = data.lineup;
    currentPlayerId = data.currentPlayerId;
    multiplier = data.multiplier;
    historyEntries = data.history;
    historyRound = data.historyRound;
    roundPlayerIds = Set<String>.from(data.roundPlayerIds);
    roundStartedAt = DateTime.now();
    isLoading = false;
  }

  String? winner() {
    return MulatschakHelper.winner(lineup);
  }

  String? currentPlayerName() {
    return currentPlayerId.isEmpty
        ? null
        : _players.displayName(currentPlayerId);
  }

  void selectPlayer(String playerId) {
    if (currentPlayerId == playerId || !lineup.containsKey(playerId)) {
      return;
    }
    _mutate(() => currentPlayerId = playerId);
  }

  void changeScore(int baseDelta) {
    if (currentPlayerId.isEmpty) {
      return;
    }
    final oldValue = lineup[currentPlayerId]!;
    final nextValue = MulatschakHelper.nextScore(
      currentValue: oldValue,
      baseDelta: baseDelta,
      multiplier: multiplier,
      muleqackEnabled: _profile.muleqackEnabled,
      triggerPoints: _profile.muleqackTriggerPoints,
      resetPoints: _profile.muleqackResetPoints,
    );
    if (nextValue == oldValue) {
      return;
    }
    final wasWinner = winner() != null;
    final changeTime = DateTime.now();
    history.execute(
      _ScoreChanged(
        controller: this,
        playerId: currentPlayerId,
        oldValue: oldValue,
        newValue: nextValue,
        changeTime: changeTime,
      ),
    );
    if (!wasWinner && winner() != null) {
      unawaited(_haptics.heavy());
    } else {
      unawaited(_haptics.light());
    }
  }

  void setMultiplier(int value) {
    if (multiplier == value) {
      return;
    }
    _mutate(() => multiplier = value);
    unawaited(_haptics.light());
  }

  void resetPlayers({bool clearHistory = false}) {
    final hasHistory = historyEntries.isNotEmpty;
    if (lineup.values.every(
          (value) => value == _profile.mulatschakStartingScore,
        ) &&
        (!clearHistory || !hasHistory)) {
      return;
    }
    final changeTime = DateTime.now();
    final oldLineup = Map<String, int>.from(lineup);
    final oldHistory = List<String>.from(historyEntries);
    final oldRound = historyRound;
    final oldRoundPlayers = Set<String>.from(roundPlayerIds);
    _pushUndoable(
      () {
        if (clearHistory) {
          lineup = Map<String, int>.from(lineup)
            ..updateAll((key, value) => _profile.mulatschakStartingScore);
          historyEntries = [];
          historyRound = MulatschakRepository.defaultHistoryRound;
          roundPlayerIds = {};
          notifyListeners();
          unawaited(_persist());
        } else {
          for (final playerId in lineup.keys) {
            final oldValue = lineup[playerId]!;
            final resetValue = _profile.mulatschakStartingScore;
            if (resetValue != oldValue) {
              _applyScore(
                playerId,
                resetValue,
                changeTime,
                (playerId) => resetValue - oldValue,
              );
            }
          }
        }
        roundStartedAt = DateTime.now();
      },
      revert: () {
        lineup = oldLineup;
        historyEntries = oldHistory;
        historyRound = oldRound;
        roundPlayerIds = oldRoundPlayers;
        notifyListeners();
        unawaited(_persist());
      },
    );
    unawaited(_haptics.light());
  }

  /// Entfernt einen Spieler aus dem Lineup (Spieler-Löschung).
  void removePlayerFromLineup(String playerId) {
    if (!lineup.containsKey(playerId)) {
      return;
    }
    _mutate(() {
      lineup = Map<String, int>.from(lineup)..remove(playerId);
      roundPlayerIds = Set<String>.from(roundPlayerIds)..remove(playerId);
      if (currentPlayerId == playerId) {
        currentPlayerId = lineup.isEmpty ? '' : lineup.keys.first;
      }
      if (lineup.isEmpty) {
        historyRound = MulatschakRepository.defaultHistoryRound;
      }
    });
  }

  /// Setzt das Lineup auf die gewählten Spieler („Wer spielt mit?“).
  /// Bereits vorhandene Punkte bleiben erhalten, neue Spieler starten mit
  /// der Startpunktzahl.
  void setLineup(List<String> playerIds) {
    final nextLineup = <String, int>{};
    for (final playerId in playerIds) {
      nextLineup[playerId] = lineup.containsKey(playerId)
          ? lineup[playerId]!
          : _profile.mulatschakStartingScore;
    }
    _mutate(() {
      lineup = nextLineup;
      roundPlayerIds = Set<String>.from(
        roundPlayerIds.where(nextLineup.containsKey),
      );
      if (!nextLineup.containsKey(currentPlayerId)) {
        currentPlayerId = nextLineup.isEmpty ? '' : nextLineup.keys.first;
      }
    });
  }

  /// Fügt einen bestehenden globalen Spieler dem Lineup hinzu.
  Future<void> addPlayerToLineup(String playerId) async {
    if (lineup.containsKey(playerId)) {
      return;
    }
    final result = MulatschakHelper.addPlayer(
      players: lineup,
      roundPlayers: roundPlayerIds,
      playerName: playerId,
    );
    _mutate(() {
      lineup = result.players;
      currentPlayerId = result.currentPlayer;
      roundPlayerIds = result.roundPlayers;
    });
  }

  /// Benennt einen Spieler im Lineup um (wird über den globalen Spieler
  /// gemacht, hier werden nur die IDs gehalten).
  void onPlayerRenamed(String oldId, String newId) {
    if (!lineup.containsKey(oldId)) {
      return;
    }
    _mutate(() {
      final reordered = <String, int>{};
      for (final entry in lineup.entries) {
        reordered[entry.key == oldId ? newId : entry.key] = entry.value;
      }
      lineup = reordered;
      if (currentPlayerId == oldId) {
        currentPlayerId = newId;
      }
      if (roundPlayerIds.contains(oldId)) {
        roundPlayerIds = Set<String>.from(roundPlayerIds)
          ..remove(oldId)
          ..add(newId);
      }
    });
  }

  void setHistoryEnabled(bool enabled) {
    _settings.setMulatschakHistoryEnabled(enabled);
  }

  /// Wendet eine Punkteänderung an und schreibt den Rundenverlauf.
  _ScoreRecord _applyScore(
    String playerId,
    int newValue,
    DateTime changeTime,
    int Function(String playerId) deltaFor,
  ) {
    final previousRound = historyRound;
    final previousRoundPlayers = Set<String>.from(roundPlayerIds);
    final points = deltaFor(playerId);
    lineup = Map<String, int>.from(lineup)..[playerId] = newValue;

    String? addedEntry;
    var nextHistory = historyEntries;
    var nextRound = historyRound;
    var nextRoundPlayers = Set<String>.from(roundPlayerIds);

    if (historyEnabled && points != 0) {
      final entry = MulatschakHistoryEntry(
        round: historyRound,
        time: HistoryUtils.formatTime(changeTime),
        playerName: _players.displayName(playerId),
        points: points,
      ).encode();
      nextHistory = [...historyEntries, entry];
      addedEntry = entry;
      nextRoundPlayers = Set<String>.from(roundPlayerIds)..add(playerId);
      if (nextRoundPlayers.length >= lineup.length) {
        nextRound += 1;
        nextRoundPlayers = {};
      }
    }

    historyEntries = nextHistory;
    historyRound = nextRound;
    roundPlayerIds = nextRoundPlayers;

    notifyListeners();
    unawaited(_persist());
    return _ScoreRecord(
      addedEntry: addedEntry,
      previousRound: previousRound,
      previousRoundPlayers: previousRoundPlayers,
    );
  }

  /// Macht eine Punkteänderung samt Rundenverlauf rückgängig.
  void _revertScore(String playerId, int oldValue, _ScoreRecord record) {
    lineup = Map<String, int>.from(lineup)..[playerId] = oldValue;
    if (record.addedEntry != null) {
      final entries = List<String>.from(historyEntries);
      final removed = entries.remove(record.addedEntry!);
      if (removed) {
        historyEntries = entries;
      }
    }
    historyRound = record.previousRound;
    roundPlayerIds = Set<String>.from(record.previousRoundPlayers);
    notifyListeners();
    unawaited(_persist());
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
      MulatschakData(
        lineup: lineup,
        currentPlayerId: currentPlayerId,
        multiplier: multiplier,
        history: historyEntries,
        historyRound: historyRound,
        roundPlayerIds: roundPlayerIds.toList(),
      ),
    );
  }
}

class _ScoreRecord {
  const _ScoreRecord({
    required this.addedEntry,
    required this.previousRound,
    required this.previousRoundPlayers,
  });

  final String? addedEntry;
  final int previousRound;
  final Set<String> previousRoundPlayers;
}

class _ScoreChanged implements UndoableCommand {
  _ScoreChanged({
    required this.controller,
    required this.playerId,
    required this.oldValue,
    required this.newValue,
    required this.changeTime,
  });

  final MulatschakController controller;
  final String playerId;
  final int oldValue;
  final int newValue;
  final DateTime changeTime;

  _ScoreRecord? _record;

  @override
  void apply() {
    _record = controller._applyScore(
      playerId,
      newValue,
      changeTime,
      (_) => newValue - oldValue,
    );
  }

  @override
  void revert() {
    controller._revertScore(playerId, oldValue, _record!);
  }
}
