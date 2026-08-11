import 'package:shared_preferences/shared_preferences.dart';

import '../../models/game_session.dart';
import '../json_codec.dart';
import '../storage_keys.dart';

/// Spielabende (GameSessions).
class SessionRepository {
  const SessionRepository();

  Future<List<GameSession>> loadSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final decoded = JsonCodec.decodeList(
      prefs.getString(StorageKeys.gameSessions),
      _decodeSession,
    );
    if (decoded == null) {
      return const <GameSession>[];
    }
    return decoded.whereType<GameSession>().toList(growable: false);
  }

  Future<void> saveSessions(List<GameSession> sessions) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      StorageKeys.gameSessions,
      JsonCodec.encode(
        sessions.map((session) => session.toJson()).toList(),
      ),
    );
  }

  static GameSession? _decodeSession(Object? item) {
    if (item is! Map) {
      return null;
    }
    try {
      return GameSession.fromJson(Map<String, dynamic>.from(item));
    } catch (_) {
      return null;
    }
  }
}
