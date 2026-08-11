import 'package:shared_preferences/shared_preferences.dart';

import '../json_codec.dart';
import '../storage_keys.dart';

class CounterData {
  final Map<String, int> counters;
  final String currentCounter;
  final Map<String, List<String>> history;

  const CounterData({
    required this.counters,
    required this.currentCounter,
    required this.history,
  });
}

/// Zähler-Daten (freier Zähler).
class CounterRepository {
  const CounterRepository();

  static const Map<String, int> defaultCounters = {'Punkte': 0};
  static const String defaultCurrentCounter = 'Punkte';

  Future<CounterData> load() async {
    final prefs = await SharedPreferences.getInstance();

    var counters = _decodeIntMap(prefs.getString(StorageKeys.counterLineup));
    if (counters.isEmpty) {
      counters = Map<String, int>.from(defaultCounters);
    }
    final storedCurrent = prefs.getString(StorageKeys.currentCounter);
    final currentCounter = counters.containsKey(storedCurrent)
        ? storedCurrent!
        : counters.keys.first;
    final history = _decodeNestedStringMap(
      prefs.getString(StorageKeys.counterHistory),
    );

    return CounterData(
      counters: counters,
      currentCounter: currentCounter,
      history: history,
    );
  }

  Future<void> save({
    required Map<String, int> counters,
    required String currentCounter,
    required Map<String, List<String>> history,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      StorageKeys.counterLineup,
      JsonCodec.encode(counters),
    );
    await prefs.setString(StorageKeys.currentCounter, currentCounter);
    await prefs.setString(
      StorageKeys.counterHistory,
      JsonCodec.encode(history),
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

  static Map<String, List<String>> _decodeNestedStringMap(String? json) {
    final decoded = JsonCodec.decodeMap(json);
    if (decoded == null) {
      return <String, List<String>>{};
    }
    return decoded.map((key, value) {
      if (value is List) {
        return MapEntry(key, value.whereType<String>().toList(growable: false));
      }
      return MapEntry(key, const <String>[]);
    });
  }
}
