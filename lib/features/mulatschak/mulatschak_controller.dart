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
  Map<String, int> _roundTricksByPlayer = {};
  bool _roundAutoCompletionSuppressed = false;
  DateTime roundStartedAt = DateTime.now();

  bool get autoCompleteRoundEnabled =>
      _settings.ruleProfile.mulatschakAutoCompleteRound;
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
    _roundTricksByPlayer = Map<String, int>.from(data.roundTricksByPlayer);
    _roundAutoCompletionSuppressed = data.roundAutoCompletionSuppressed;
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
    final playerId = currentPlayerId;
    final oldValue = lineup[playerId];
    if (playerId.isEmpty || oldValue == null) {
      return;
    }
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
    if (autoCompleteRoundEnabled) {
      history.execute(
        _AutoCompletingScoreChanged(
          controller: this,
          playerId: playerId,
          oldValue: oldValue,
          newValue: nextValue,
          changeTime: changeTime,
          baseDelta: baseDelta,
        ),
      );
    } else {
      _resetAutomaticRoundState();
      history.execute(
        _ScoreChanged(
          controller: this,
          playerId: playerId,
          oldValue: oldValue,
          newValue: nextValue,
          changeTime: changeTime,
        ),
      );
    }
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
    final oldRoundTricks = Map<String, int>.from(_roundTricksByPlayer);
    final oldRoundAutoSuppressed = _roundAutoCompletionSuppressed;
    _pushUndoable(
      () {
        if (clearHistory) {
          lineup = Map<String, int>.from(lineup)
            ..updateAll((key, value) => _profile.mulatschakStartingScore);
          historyEntries = [];
          historyRound = MulatschakRepository.defaultHistoryRound;
          roundPlayerIds = {};
          _resetAutomaticRoundState();
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
        _resetAutomaticRoundState();
        roundStartedAt = DateTime.now();
        unawaited(_persist());
      },
      revert: () {
        lineup = oldLineup;
        historyEntries = oldHistory;
        historyRound = oldRound;
        roundPlayerIds = oldRoundPlayers;
        _roundTricksByPlayer = oldRoundTricks;
        _roundAutoCompletionSuppressed = oldRoundAutoSuppressed;
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
      _roundTricksByPlayer = Map<String, int>.from(_roundTricksByPlayer)
        ..remove(playerId);
      if (currentPlayerId == playerId) {
        currentPlayerId = lineup.isEmpty ? '' : lineup.keys.first;
      }
      if (lineup.isEmpty) {
        historyRound = MulatschakRepository.defaultHistoryRound;
        roundPlayerIds = {};
        _resetAutomaticRoundState();
      } else if (roundPlayerIds.length >= lineup.length) {
        historyRound += 1;
        roundPlayerIds = {};
        _resetAutomaticRoundState();
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
      _roundTricksByPlayer = Map<String, int>.fromEntries(
        _roundTricksByPlayer.entries.where(
          (entry) => nextLineup.containsKey(entry.key),
        ),
      );
      if (!nextLineup.containsKey(currentPlayerId)) {
        currentPlayerId = nextLineup.isEmpty ? '' : nextLineup.keys.first;
      }
      if (nextLineup.isEmpty) {
        historyRound = MulatschakRepository.defaultHistoryRound;
        roundPlayerIds = {};
        _resetAutomaticRoundState();
      } else if (roundPlayerIds.length >= nextLineup.length) {
        historyRound += 1;
        roundPlayerIds = {};
        _resetAutomaticRoundState();
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
      _roundTricksByPlayer = Map<String, int>.from(_roundTricksByPlayer)
        ..remove(playerId);
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
      final tricks = _roundTricksByPlayer.remove(oldId);
      if (tricks != null) {
        _roundTricksByPlayer = Map<String, int>.from(_roundTricksByPlayer)
          ..[newId] = tricks;
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
    var completedRound = false;

    if (points != 0) {
      nextRoundPlayers = Set<String>.from(roundPlayerIds)..add(playerId);
      if (nextRoundPlayers.length >= lineup.length) {
        nextRound += 1;
        nextRoundPlayers = {};
        completedRound = true;
      }
      final entry = MulatschakHistoryEntry(
        round: historyRound,
        time: HistoryUtils.formatTime(changeTime),
        playerName: _players.displayName(playerId),
        points: points,
      ).encode();
      nextHistory = [...historyEntries, entry];
      addedEntry = entry;
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
      completedRound: completedRound,
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

  void _applyAutoCompletingScore({
    required String playerId,
    required int oldValue,
    required int newValue,
    required DateTime changeTime,
    required int baseDelta,
  }) {
    final isFirstScoreForPlayer = !roundPlayerIds.contains(playerId);

    // +5 als erster Eintrag eines Spielers bedeutet „gefallen“. In dieser
    // Runde werden deshalb keine Punkte mehr automatisch vergeben.
    if (baseDelta == 5 && isFirstScoreForPlayer) {
      _roundAutoCompletionSuppressed = true;
      _roundTricksByPlayer = {};
    }

    final scoreRecord = _applyScore(
      playerId,
      newValue,
      changeTime,
      (_) => newValue - oldValue,
    );
    if (scoreRecord.completedRound) {
      _resetAutomaticRoundState();
      unawaited(_persist());
      return;
    }

    // +1 bedeutet „gegangen“ und ist kein Stich. Der Spieler hat damit seine
    // neuen Rundenpunkte bereits erhalten und wird bei automatischem +5 über
    // [roundPlayerIds] nicht mehr berücksichtigt.
    if (baseDelta == 1) {
      _roundTricksByPlayer = Map<String, int>.from(_roundTricksByPlayer)
        ..remove(playerId);
    }

    if (_roundAutoCompletionSuppressed) {
      unawaited(_persist());
      return;
    }

    final trickDelta = switch (baseDelta) {
      -5 => 5,
      -1 => 1,
      _ => 0,
    };
    if (trickDelta > 0) {
      _roundTricksByPlayer = Map<String, int>.from(_roundTricksByPlayer)
        ..update(
          playerId,
          (tricks) => tricks + trickDelta,
          ifAbsent: () => trickDelta,
        );
    }

    final totalTricks = _roundTricksByPlayer.values.fold<int>(
      0,
      (sum, tricks) => sum + tricks,
    );
    if (totalTricks >= 5) {
      final roundBeforeAutoCompletion = historyRound;
      final playersAwaitingPoints = lineup.keys
          .where((playerId) => !roundPlayerIds.contains(playerId))
          .toList(growable: false);
      for (final otherPlayerId in playersAwaitingPoints) {
        final otherOldValue = lineup[otherPlayerId];
        if (otherOldValue == null) {
          continue;
        }
        final otherNewValue = MulatschakHelper.nextScore(
          currentValue: otherOldValue,
          baseDelta: 5,
          multiplier: multiplier,
          muleqackEnabled: _profile.muleqackEnabled,
          triggerPoints: _profile.muleqackTriggerPoints,
          resetPoints: _profile.muleqackResetPoints,
        );
        _applyScore(
          otherPlayerId,
          otherNewValue,
          changeTime,
          (_) => otherNewValue - otherOldValue,
        );
      }
      _resetAutomaticRoundState();
      if (historyRound == roundBeforeAutoCompletion) {
        // Ein Sonderfall wie ein Muleqack-Reset kann denselben Punktestand
        // ergeben. Dann bleibt es dieselbe Runde und weitere Automatik wird
        // bis zum manuellen Rundenabschluss unterdrückt.
        _roundAutoCompletionSuppressed = true;
      }
      unawaited(_persist());
      return;
    }

    unawaited(_persist());
  }

  void _resetAutomaticRoundState() {
    _roundTricksByPlayer = {};
    _roundAutoCompletionSuppressed = false;
  }

  _MulatschakSnapshot _snapshot() => _MulatschakSnapshot(
    lineup: Map<String, int>.from(lineup),
    history: List<String>.from(historyEntries),
    historyRound: historyRound,
    roundPlayerIds: Set<String>.from(roundPlayerIds),
    roundTricksByPlayer: Map<String, int>.from(_roundTricksByPlayer),
    roundAutoCompletionSuppressed: _roundAutoCompletionSuppressed,
  );

  void _restore(_MulatschakSnapshot snapshot) {
    lineup = Map<String, int>.from(snapshot.lineup);
    historyEntries = List<String>.from(snapshot.history);
    historyRound = snapshot.historyRound;
    roundPlayerIds = Set<String>.from(snapshot.roundPlayerIds);
    _roundTricksByPlayer = Map<String, int>.from(snapshot.roundTricksByPlayer);
    _roundAutoCompletionSuppressed = snapshot.roundAutoCompletionSuppressed;
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
        roundTricksByPlayer: _roundTricksByPlayer,
        roundAutoCompletionSuppressed: _roundAutoCompletionSuppressed,
      ),
    );
  }
}

class _ScoreRecord {
  const _ScoreRecord({
    required this.addedEntry,
    required this.previousRound,
    required this.previousRoundPlayers,
    required this.completedRound,
  });

  final String? addedEntry;
  final int previousRound;
  final Set<String> previousRoundPlayers;
  final bool completedRound;
}

class _MulatschakSnapshot {
  const _MulatschakSnapshot({
    required this.lineup,
    required this.history,
    required this.historyRound,
    required this.roundPlayerIds,
    required this.roundTricksByPlayer,
    required this.roundAutoCompletionSuppressed,
  });

  final Map<String, int> lineup;
  final List<String> history;
  final int historyRound;
  final Set<String> roundPlayerIds;
  final Map<String, int> roundTricksByPlayer;
  final bool roundAutoCompletionSuppressed;
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

class _AutoCompletingScoreChanged implements UndoableCommand {
  _AutoCompletingScoreChanged({
    required this.controller,
    required this.playerId,
    required this.oldValue,
    required this.newValue,
    required this.changeTime,
    required this.baseDelta,
  });

  final MulatschakController controller;
  final String playerId;
  final int oldValue;
  final int newValue;
  final DateTime changeTime;
  final int baseDelta;

  _MulatschakSnapshot? _snapshot;

  @override
  void apply() {
    _snapshot ??= controller._snapshot();
    controller._applyAutoCompletingScore(
      playerId: playerId,
      oldValue: oldValue,
      newValue: newValue,
      changeTime: changeTime,
      baseDelta: baseDelta,
    );
  }

  @override
  void revert() {
    controller._restore(_snapshot!);
  }
}
