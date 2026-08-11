import 'dart:async';

import '../../commands/callback_command.dart';
import '../../core/haptics_service.dart';
import '../../models/rule_profile.dart';
import '../../persistence/repositories/hosn_obe_repository.dart';
import '../feature_controller.dart';
import '../players/players_controller.dart';
import '../settings/settings_controller.dart';
import 'hosn_obe_helper.dart';

/// State und Geschäftslogik für Hosn Obe.
class HosnObeController extends FeatureController {
  HosnObeController({
    required HosnObeRepository repository,
    required SettingsController settings,
    required PlayersController players,
    required HapticsService haptics,
  }) : _repository = repository,
       _settings = settings,
       _players = players,
       _haptics = haptics;

  final HosnObeRepository _repository;
  final SettingsController _settings;
  final PlayersController _players;
  final HapticsService _haptics;

  Map<String, int> lineup = {};
  String currentPlayerId = '';
  DateTime roundStartedAt = DateTime.now();

  RuleProfile get _profile => _settings.ruleProfile;

  @override
  Future<void> load() async {
    final data = await _repository.load();
    lineup = data.lineup;
    currentPlayerId = data.currentPlayerId;
    roundStartedAt = DateTime.now();
    isLoading = false;
  }

  String? winner() {
    return HosnObeHelper.winner(lineup);
  }

  String? currentPlayerName() {
    return currentPlayerId.isEmpty ? null : _players.displayName(currentPlayerId);
  }

  void selectPlayer(String playerId) {
    if (currentPlayerId == playerId || !lineup.containsKey(playerId)) {
      return;
    }
    _mutate(() => currentPlayerId = playerId);
  }

  void changeScore(int delta) {
    if (currentPlayerId.isEmpty) {
      return;
    }
    final oldValue = lineup[currentPlayerId]!;
    final nextValue = oldValue + delta;
    if (nextValue < 0) {
      return;
    }
    final wasWinner = winner() != null;
    _pushUndoable(
      () => _applyScore(currentPlayerId, nextValue),
      revert: () => _applyScore(currentPlayerId, oldValue),
    );
    if (!wasWinner && winner() != null) {
      unawaited(_haptics.heavy());
    } else {
      unawaited(_haptics.light());
    }
  }

  void resetPlayers() {
    if (lineup.values.every((value) => value == _profile.hosnObeStartingLives)) {
      return;
    }
    final oldLineup = Map<String, int>.from(lineup);
    _pushUndoable(() {
      lineup = HosnObeHelper.resetPlayers(
        lineup,
        startingLives: _profile.hosnObeStartingLives,
      );
      roundStartedAt = DateTime.now();
      notifyListeners();
      unawaited(_persist());
    }, revert: () {
      lineup = oldLineup;
      notifyListeners();
      unawaited(_persist());
    });
    unawaited(_haptics.light());
  }

  /// Entfernt einen Spieler aus dem Lineup (Spieler-Löschung).
  void removePlayerFromLineup(String playerId) {
    if (!lineup.containsKey(playerId)) {
      return;
    }
    _mutate(() {
      lineup = Map<String, int>.from(lineup)..remove(playerId);
      if (currentPlayerId == playerId) {
        currentPlayerId = lineup.isEmpty ? '' : lineup.keys.first;
      }
    });
  }

  /// Fügt einen bestehenden globalen Spieler dem Lineup hinzu.
  Future<void> addPlayerToLineup(String playerId) async {
    if (lineup.containsKey(playerId)) {
      return;
    }
    final result = HosnObeHelper.addPlayer(
      players: lineup,
      playerName: playerId,
      startingLives: _profile.hosnObeStartingLives,
    );
    _mutate(() {
      lineup = result.players;
      currentPlayerId = result.currentPlayer;
    });
  }

  /// Benennt einen Spieler im Lineup um (IDs statt Namen).
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
    });
  }

  void _applyScore(String playerId, int value) {
    lineup = HosnObeHelper.updateScore(
      players: lineup,
      currentPlayer: playerId,
      score: value,
    );
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
    return _repository.save(lineup: lineup, currentPlayerId: currentPlayerId);
  }
}
