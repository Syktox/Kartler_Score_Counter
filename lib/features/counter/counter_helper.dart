import 'dart:collection';

import '../../utils/history_utils.dart';
import '../../utils/name_utils.dart';
import '../../utils/ordered_map_utils.dart';

class CounterHelper {
  const CounterHelper._();

  static bool isNameValid(String counterName, Iterable<String> counters) {
    return NameUtils.isUnique(counterName, counters);
  }

  static bool canDecrement({required int score, required bool allowNegative}) {
    return allowNegative || score > 0;
  }

  static Map<String, List<String>> recordHistory({
    required bool enabled,
    required Map<String, List<String>> history,
    required String counterName,
    required String action,
  }) {
    if (!enabled) {
      return history;
    }

    final currentHistory = history[counterName] ?? const <String>[];

    return Map<String, List<String>>.from(history)
      ..[counterName] = [
        '${HistoryUtils.formatTime(DateTime.now())} - $action.',
        ...currentHistory,
      ];
  }

  static ({Map<String, int> counters, Map<String, List<String>> history})
  updateScore({
    required Map<String, int> counters,
    required Map<String, List<String>> history,
    required String currentCounter,
    required bool historyEnabled,
    required int score,
    required String action,
  }) {
    return (
      counters: Map<String, int>.from(counters)..[currentCounter] = score,
      history: recordHistory(
        enabled: historyEnabled,
        history: history,
        counterName: currentCounter,
        action: action,
      ),
    );
  }

  static ({Map<String, int> counters, String currentCounter}) addCounter({
    required Map<String, int> counters,
    required String counterName,
  }) {
    return (
      counters: Map<String, int>.from(counters)..[counterName] = 0,
      currentCounter: counterName,
    );
  }

  static ({
    LinkedHashMap<String, int> counters,
    LinkedHashMap<String, List<String>> history,
    String currentCounter,
  })
  renameCounter({
    required Map<String, int> counters,
    required Map<String, List<String>> history,
    required String currentCounter,
    required String oldName,
    required String newName,
  }) {
    final renamedCounters = OrderedMapUtils.renameSelectedKey(
      values: counters,
      selectedKey: currentCounter,
      oldKey: oldName,
      newKey: newName,
    );

    return (
      counters: renamedCounters.values,
      history: OrderedMapUtils.renameKey(
        history,
        oldName,
        newName,
        copyValue: List<String>.from,
      ),
      currentCounter: renamedCounters.selectedKey,
    );
  }

  static ({
    Map<String, int> counters,
    Map<String, List<String>> history,
    String currentCounter,
  })
  deleteCounter({
    required Map<String, int> counters,
    required Map<String, List<String>> history,
    required String currentCounter,
    required String counterName,
  }) {
    final removedCounter = OrderedMapUtils.removeSelectedKey(
      values: counters,
      selectedKey: currentCounter,
      key: counterName,
    );
    final nextHistory = Map<String, List<String>>.from(history)
      ..remove(counterName);

    return (
      counters: removedCounter.values,
      history: nextHistory,
      currentCounter: removedCounter.selectedKey,
    );
  }

  static LinkedHashMap<String, int>? reorderCounters(
    Map<String, int> counters,
    int oldIndex,
    int newIndex,
  ) {
    return OrderedMapUtils.reorder(counters, oldIndex, newIndex);
  }
}
