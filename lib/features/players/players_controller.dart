import 'dart:async';

import '../../core/haptics_service.dart';
import '../../core/id_generator.dart';
import '../../models/player.dart';
import '../../persistence/repositories/player_repository.dart';
import '../../utils/name_utils.dart';
import '../feature_controller.dart';

/// Globale Spielerprofile, die in allen Spielmodi wiederverwendet werden.
class PlayersController extends FeatureController {
  PlayersController({
    required PlayerRepository repository,
    required HapticsService haptics,
  }) : _repository = repository,
       _haptics = haptics;

  final PlayerRepository _repository;
  final HapticsService _haptics;

  List<Player> _players = const [];

  List<Player> get players => List.unmodifiable(_players);

  Player? playerById(String? id) {
    if (id == null || id.isEmpty) {
      return null;
    }
    for (final player in _players) {
      if (player.id == id) {
        return player;
      }
    }
    return null;
  }

  /// Anzeigename eines Spielers; für unbekannte IDs wird die ID gezeigt.
  String displayName(String? id) {
    final player = playerById(id);
    if (player != null) {
      return player.displayName;
    }
    if (id == null || id.isEmpty) {
      return '—';
    }
    return id;
  }

  bool isNameValid(String name, [String? ignoredId]) {
    return NameUtils.isUniqueExcept(
      name,
      _players.map((player) => player.name),
      ignoredId == null ? '' : (playerById(ignoredId)?.name ?? ''),
    );
  }

  @override
  Future<void> load() async {
    _players = await _repository.loadPlayers();
    isLoading = false;
  }

  /// Legt einen neuen globalen Spieler an.
  Future<Player?> addPlayer(String name) async {
    final cleaned = NameUtils.clean(name);
    if (!isNameValid(cleaned)) {
      return null;
    }
    final player = Player(
      id: IdGenerator.newId(),
      name: cleaned,
      createdAt: DateTime.now(),
    );
    _players = [..._players, player];
    notifyListeners();
    await _persist();
    await _haptics.light();
    return player;
  }

  /// Benennt einen globalen Spieler um.
  Future<Player?> renamePlayer(String id, String newName) async {
    final current = playerById(id);
    if (current == null) {
      return null;
    }
    final cleaned = NameUtils.clean(newName);
    if (!isNameValid(cleaned, id)) {
      return null;
    }
    final updated = current.copyWith(name: cleaned);
    _players = [
      for (final player in _players)
        if (player.id == id) updated else player,
    ];
    notifyListeners();
    await _persist();
    await _haptics.light();
    return updated;
  }

  /// Löscht einen globalen Spieler. Achtung: Lineups, in denen der Spieler
  /// vorkommt, müssen vorher von den Modus-Controllern bereinigt werden.
  Future<void> deletePlayer(String id) async {
    final player = playerById(id);
    if (player == null) {
      return;
    }
    _players = _players.where((entry) => entry.id != id).toList();
    notifyListeners();
    await _persist();
    await _haptics.light();
  }

  Future<void> _persist() {
    return _repository.savePlayers(_players);
  }
}
