import 'package:shared_preferences/shared_preferences.dart';

import '../json_codec.dart';
import '../storage_keys.dart';

class MulatschakData {
  final Map<String, int> lineup;
  final String currentPlayerId;
  final int multiplier;
  final List<String> history;
  final int historyRound;
  final List<String> roundPlayerIds;
  final Map<String, int> roundTricksByPlayer;
  final bool roundAutoCompletionSuppressed;

  const MulatschakData({
    required this.lineup,
    required this.currentPlayerId,
    required this.multiplier,
    required this.history,
    required this.historyRound,
    required this.roundPlayerIds,
    this.roundTricksByPlayer = const {},
    this.roundAutoCompletionSuppressed = false,
  });
}

/// Mulatschak-Daten (Lineup aus globalen Spieler-IDs mit Punkten).
class MulatschakRepository {
  const MulatschakRepository();

  static const int defaultMultiplier = 1;
  static const int defaultHistoryRound = 1;

  Future<MulatschakData> load() async {
    final prefs = await SharedPreferences.getInstance();

    final lineup = _decodeIntMap(prefs.getString(StorageKeys.mulatschakLineup));
    final storedCurrent = prefs.getString(StorageKeys.currentMulatschakPlayer);
    final currentPlayerId = lineup.containsKey(storedCurrent)
        ? storedCurrent!
        : (lineup.isEmpty ? '' : lineup.keys.first);
    final storedMultiplier = prefs.getInt(StorageKeys.mulatschakMultiplier);
    final storedHistoryRound = prefs.getInt(StorageKeys.mulatschakHistoryRound);
    final roundPlayerIds = _decodeStringList(
      prefs.getString(StorageKeys.mulatschakRoundPlayers),
    );
    final roundTricksByPlayer = _decodeIntMap(
      prefs.getString(StorageKeys.mulatschakRoundTricks),
    );
    final roundAutoCompletionSuppressed =
        prefs.getBool(StorageKeys.mulatschakRoundAutoSuppressed) ?? false;

    return MulatschakData(
      lineup: lineup,
      currentPlayerId: currentPlayerId,
      multiplier: storedMultiplier != null && storedMultiplier > 0
          ? storedMultiplier
          : defaultMultiplier,
      history: _decodeStringList(
        prefs.getString(StorageKeys.mulatschakHistory),
      ),
      historyRound: storedHistoryRound != null && storedHistoryRound > 0
          ? storedHistoryRound
          : defaultHistoryRound,
      roundPlayerIds: roundPlayerIds
          .where(lineup.containsKey)
          .toList(growable: false),
      roundTricksByPlayer: Map<String, int>.fromEntries(
        roundTricksByPlayer.entries.where(
          (entry) => lineup.containsKey(entry.key) && entry.value > 0,
        ),
      ),
      roundAutoCompletionSuppressed: roundAutoCompletionSuppressed,
    );
  }

  Future<void> save(MulatschakData data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      StorageKeys.mulatschakLineup,
      JsonCodec.encode(data.lineup),
    );
    await prefs.setString(
      StorageKeys.currentMulatschakPlayer,
      data.currentPlayerId,
    );
    await prefs.setInt(StorageKeys.mulatschakMultiplier, data.multiplier);
    await prefs.setString(
      StorageKeys.mulatschakHistory,
      JsonCodec.encode(data.history),
    );
    await prefs.setInt(StorageKeys.mulatschakHistoryRound, data.historyRound);
    await prefs.setString(
      StorageKeys.mulatschakRoundPlayers,
      JsonCodec.encode(data.roundPlayerIds),
    );
    await prefs.setString(
      StorageKeys.mulatschakRoundTricks,
      JsonCodec.encode(data.roundTricksByPlayer),
    );
    await prefs.setBool(
      StorageKeys.mulatschakRoundAutoSuppressed,
      data.roundAutoCompletionSuppressed,
    );
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

  static List<String> _decodeStringList(String? json) {
    final decoded = JsonCodec.decodeList(
      json,
      (item) => item is String ? item : null,
    );
    if (decoded == null) {
      return <String>[];
    }
    return decoded.whereType<String>().toList(growable: false);
  }
}
