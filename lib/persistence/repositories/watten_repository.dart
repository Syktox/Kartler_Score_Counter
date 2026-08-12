import 'package:shared_preferences/shared_preferences.dart';

import '../../models/watten_game.dart';
import '../json_codec.dart';
import '../storage_keys.dart';

class WattenData {
  final Map<String, WattenGame> games;
  final String currentGame;
  final List<String> meTeam;
  final List<String> youTeam;
  final List<String> history;

  const WattenData({
    required this.games,
    required this.currentGame,
    this.meTeam = const [],
    this.youTeam = const [],
    this.history = const [],
  });
}

/// Watten-Daten (benannte Spiele mit zwei Seiten und gewählten Teams).
class WattenRepository {
  const WattenRepository();

  static const Map<String, WattenGame> defaultGames = {
    'Spiel 1': WattenGame(me: 0, you: 0),
  };
  static const String defaultCurrentGame = 'Spiel 1';

  Future<WattenData> load() async {
    final prefs = await SharedPreferences.getInstance();

    var games = _decodeGames(prefs.getString(StorageKeys.wattenLineup));
    if (games.isEmpty) {
      games = Map<String, WattenGame>.from(defaultGames);
    }
    final storedCurrent = prefs.getString(StorageKeys.currentWattenGame);
    final currentGame = games.containsKey(storedCurrent)
        ? storedCurrent!
        : games.keys.first;

    return WattenData(
      games: games,
      currentGame: currentGame,
      meTeam: _decodeTeam(prefs.getString(StorageKeys.wattenTeamMe)),
      youTeam: _decodeTeam(prefs.getString(StorageKeys.wattenTeamYou)),
      history: _decodeStringList(prefs.getString(StorageKeys.wattenHistory)),
    );
  }

  Future<void> save({
    required Map<String, WattenGame> games,
    required String currentGame,
    List<String> meTeam = const [],
    List<String> youTeam = const [],
    List<String> history = const [],
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      StorageKeys.wattenLineup,
      JsonCodec.encode(
        games.map((key, value) => MapEntry(key, value.toJson())),
      ),
    );
    await prefs.setString(StorageKeys.currentWattenGame, currentGame);
    await prefs.setString(StorageKeys.wattenTeamMe, JsonCodec.encode(meTeam));
    await prefs.setString(StorageKeys.wattenTeamYou, JsonCodec.encode(youTeam));
    await prefs.setString(StorageKeys.wattenHistory, JsonCodec.encode(history));
  }

  static Map<String, WattenGame> _decodeGames(String? json) {
    final decoded = JsonCodec.decodeMap(json);
    if (decoded == null) {
      return <String, WattenGame>{};
    }
    return decoded.map((key, value) {
      if (value is! Map) {
        return MapEntry(key, const WattenGame(me: 0, you: 0));
      }
      return MapEntry(
        key,
        WattenGame.fromJson(Map<String, dynamic>.from(value)),
      );
    });
  }

  static List<String> _decodeTeam(String? json) {
    final decoded = JsonCodec.decodeList<String>(
      json,
      (item) => item is String ? item : '',
    );
    if (decoded == null) {
      return const <String>[];
    }
    return decoded.where((id) => id.isNotEmpty).toList(growable: false);
  }

  static List<String> _decodeStringList(String? json) {
    final decoded = JsonCodec.decodeList(
      json,
      (item) => item is String ? item : null,
    );
    if (decoded == null) {
      return const <String>[];
    }
    return decoded.whereType<String>().toList(growable: false);
  }
}
