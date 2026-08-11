import 'package:shared_preferences/shared_preferences.dart';

import '../../models/watten_game.dart';
import '../json_codec.dart';
import '../storage_keys.dart';

class WattenData {
  final Map<String, WattenGame> games;
  final String currentGame;

  const WattenData({required this.games, required this.currentGame});
}

/// Watten-Daten (benannte Spiele mit zwei Seiten).
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

    return WattenData(games: games, currentGame: currentGame);
  }

  Future<void> save({
    required Map<String, WattenGame> games,
    required String currentGame,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      StorageKeys.wattenLineup,
      JsonCodec.encode(
        games.map((key, value) => MapEntry(key, value.toJson())),
      ),
    );
    await prefs.setString(StorageKeys.currentWattenGame, currentGame);
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
}
