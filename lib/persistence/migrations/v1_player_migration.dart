import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/id_generator.dart';
import '../../models/player.dart';
import '../../models/watten_game.dart';
import '../migrations/app_migration.dart';
import '../storage_keys.dart';

/// Schema 0 → 1: Globale Spieler mit stabilen IDs.
///
/// Erzeugt aus den bisherigen mode-internen Spielern (Mulatschak,
/// Hosn Obe) eine globale Spielerliste und schreibt pro Modus ein
/// Lineup (Spieler-ID → Punkte). Zähler- und Watten-Daten werden unter
/// neuen Keys abgelegt. Die bisherige Mulatschak-Rundenliste wird von
/// Namen auf Spieler-IDs umgestellt.
class V1PlayerMigration implements AppMigration {
  @override
  int get fromVersion => 0;

  @override
  int get toVersion => 1;

  @override
  Future<void> run(SharedPreferences prefs) async {
    final mulatschakScores = _decodeIntMap(
      prefs.getString(LegacyStorageKeys.mulatschakPlayers),
    );
    final hosnObeScores = _decodeIntMap(
      prefs.getString(LegacyStorageKeys.hosnObePlayers),
    );

    final players = <Player>[];
    final idByName = <String, String>{};

    String idFor(String name) {
      final normalized = _normalize(name);
      final existing = idByName[normalized];
      if (existing != null) {
        return existing;
      }
      final id = IdGenerator.newId();
      players.add(Player(id: id, name: name, createdAt: DateTime.now()));
      idByName[normalized] = id;
      return id;
    }

    final mulatschakLineup = <String, int>{};
    for (final entry in mulatschakScores.entries) {
      mulatschakLineup[idFor(entry.key)] = entry.value;
    }
    final hosnObeLineup = <String, int>{};
    for (final entry in hosnObeScores.entries) {
      hosnObeLineup[idFor(entry.key)] = entry.value;
    }

    await prefs.setString(
      StorageKeys.players,
      jsonEncode(players.map((player) => player.toJson()).toList()),
    );
    if (mulatschakLineup.isNotEmpty) {
      await prefs.setString(
        StorageKeys.mulatschakLineup,
        jsonEncode(mulatschakLineup),
      );
    }
    if (hosnObeLineup.isNotEmpty) {
      await prefs.setString(
        StorageKeys.hosnObeLineup,
        jsonEncode(hosnObeLineup),
      );
    }

    final currentMulatschak = prefs.getString(
      StorageKeys.currentMulatschakPlayer,
    );
    if (currentMulatschak != null) {
      await prefs.setString(
        StorageKeys.currentMulatschakPlayer,
        idByName[_normalize(currentMulatschak)] ??
            (mulatschakLineup.isEmpty ? '' : mulatschakLineup.keys.first),
      );
    }
    final currentHosnObe = prefs.getString(StorageKeys.currentHosnObePlayer);
    if (currentHosnObe != null) {
      await prefs.setString(
        StorageKeys.currentHosnObePlayer,
        idByName[_normalize(currentHosnObe)] ??
            (hosnObeLineup.isEmpty ? '' : hosnObeLineup.keys.first),
      );
    }

    final roundPlayers = _decodeStringList(
      prefs.getString(StorageKeys.mulatschakRoundPlayers),
    );
    if (roundPlayers.isNotEmpty) {
      final roundPlayerIds = roundPlayers
          .map((name) => idByName[_normalize(name)])
          .whereType<String>()
          .toList(growable: false);
      if (roundPlayerIds.isNotEmpty) {
        await prefs.setString(
          StorageKeys.mulatschakRoundPlayers,
          jsonEncode(roundPlayerIds),
        );
      }
    }

    final counters = _decodeIntMap(prefs.getString(LegacyStorageKeys.counters));
    if (counters.isNotEmpty) {
      await prefs.setString(StorageKeys.counterLineup, jsonEncode(counters));
    }
    final wattenGames = _decodeWattenGames(
      prefs.getString(LegacyStorageKeys.wattenGames),
    );
    if (wattenGames.isNotEmpty) {
      await prefs.setString(
        StorageKeys.wattenLineup,
        jsonEncode(
          wattenGames.map((key, value) => MapEntry(key, value.toJson())),
        ),
      );
    }

    const legacyKeys = [
      LegacyStorageKeys.counters,
      LegacyStorageKeys.wattenGames,
      LegacyStorageKeys.mulatschakPlayers,
      LegacyStorageKeys.hosnObePlayers,
      LegacyStorageKeys.muleqackEnabled,
      LegacyStorageKeys.muleqackTriggerPoints,
      LegacyStorageKeys.muleqackResetPoints,
    ];
    for (final key in legacyKeys) {
      await prefs.remove(key);
    }
  }

  static Map<String, int> _decodeIntMap(String? json) {
    if (json == null || json.isEmpty) {
      return <String, int>{};
    }
    try {
      final decoded = jsonDecode(json);
      if (decoded is! Map<String, dynamic>) {
        return <String, int>{};
      }
      return decoded.map((key, value) => MapEntry(key, (value as num).toInt()));
    } catch (_) {
      return <String, int>{};
    }
  }

  static Map<String, WattenGame> _decodeWattenGames(String? json) {
    if (json == null || json.isEmpty) {
      return <String, WattenGame>{};
    }
    try {
      final decoded = jsonDecode(json);
      if (decoded is! Map<String, dynamic>) {
        return <String, WattenGame>{};
      }
      return decoded.map((key, value) {
        if (value is! Map<String, dynamic>) {
          return MapEntry(key, const WattenGame(me: 0, you: 0));
        }
        return MapEntry(key, WattenGame.fromJson(value));
      });
    } catch (_) {
      return <String, WattenGame>{};
    }
  }

  static List<String> _decodeStringList(String? json) {
    if (json == null || json.isEmpty) {
      return <String>[];
    }
    try {
      final decoded = jsonDecode(json);
      if (decoded is List) {
        return decoded.whereType<String>().toList(growable: false);
      }
    } catch (_) {
      return <String>[];
    }
    return <String>[];
  }

  static String _normalize(String name) {
    return name.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();
  }
}
