import 'package:shared_preferences/shared_preferences.dart';

import '../json_codec.dart';
import '../storage_keys.dart';

class HosnObeData {
  final Map<String, int> lineup;
  final String currentPlayerId;

  const HosnObeData({required this.lineup, required this.currentPlayerId});
}

/// Hosn-Obe-Daten (Lineup aus globalen Spieler-IDs mit Leben).
class HosnObeRepository {
  const HosnObeRepository();

  Future<HosnObeData> load() async {
    final prefs = await SharedPreferences.getInstance();

    final lineup = _decodeIntMap(prefs.getString(StorageKeys.hosnObeLineup));
    final storedCurrent = prefs.getString(StorageKeys.currentHosnObePlayer);
    final currentPlayerId = lineup.containsKey(storedCurrent)
        ? storedCurrent!
        : (lineup.isEmpty ? '' : lineup.keys.first);

    return HosnObeData(lineup: lineup, currentPlayerId: currentPlayerId);
  }

  Future<void> save({
    required Map<String, int> lineup,
    required String currentPlayerId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      StorageKeys.hosnObeLineup,
      JsonCodec.encode(lineup),
    );
    await prefs.setString(StorageKeys.currentHosnObePlayer, currentPlayerId);
  }

  static Map<String, int> _decodeIntMap(String? json) {
    final decoded = JsonCodec.decodeMap(json);
    if (decoded == null) {
      return <String, int>{};
    }
    return decoded.map((key, value) {
      return MapEntry(key, value is num ? value.toInt() : 0);
    });
  }
}
