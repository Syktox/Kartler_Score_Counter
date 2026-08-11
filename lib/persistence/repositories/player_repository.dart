import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../models/player.dart';
import '../json_codec.dart';
import '../storage_keys.dart';

/// Globale Spielerprofile.
class PlayerRepository {
  const PlayerRepository();

  Future<List<Player>> loadPlayers() async {
    final prefs = await SharedPreferences.getInstance();
    final decoded = JsonCodec.decodeList(
      prefs.getString(StorageKeys.players),
      _decodePlayer,
    );
    if (decoded == null) {
      return const <Player>[];
    }
    return decoded.whereType<Player>().toList(growable: false);
  }

  Future<void> savePlayers(List<Player> players) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      StorageKeys.players,
      jsonEncode(players.map((player) => player.toJson()).toList()),
    );
  }

  static Player? _decodePlayer(Object? item) {
    if (item is! Map) {
      return null;
    }
    return Player.fromJson(Map<String, dynamic>.from(item));
  }
}
