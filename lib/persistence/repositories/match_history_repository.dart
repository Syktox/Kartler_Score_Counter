import 'package:shared_preferences/shared_preferences.dart';

import '../../models/completed_match.dart';
import '../json_codec.dart';
import '../storage_keys.dart';

/// Strukturierte Match-History, Grundlage der Statistiken.
class MatchHistoryRepository {
  const MatchHistoryRepository();

  Future<List<CompletedMatch>> loadMatches() async {
    final prefs = await SharedPreferences.getInstance();
    final decoded = JsonCodec.decodeList(
      prefs.getString(StorageKeys.matchHistory),
      _decodeMatch,
    );
    if (decoded == null) {
      return const <CompletedMatch>[];
    }
    return decoded.whereType<CompletedMatch>().toList(growable: false);
  }

  Future<void> saveMatches(List<CompletedMatch> matches) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      StorageKeys.matchHistory,
      JsonCodec.encode(matches.map((match) => match.toJson()).toList()),
    );
  }

  static CompletedMatch? _decodeMatch(Object? item) {
    if (item is! Map) {
      return null;
    }
    try {
      return CompletedMatch.fromJson(Map<String, dynamic>.from(item));
    } catch (_) {
      return null;
    }
  }
}
