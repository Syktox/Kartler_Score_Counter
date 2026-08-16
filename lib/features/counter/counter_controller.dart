import 'dart:async';
import 'dart:collection';

import '../../commands/callback_command.dart';
import '../../core/haptics_service.dart';
import '../../persistence/repositories/counter_repository.dart';
import '../../utils/history_utils.dart';
import '../feature_controller.dart';
import '../settings/settings_controller.dart';
import 'counter_helper.dart';

/// State und Geschäftslogik des freien Zählers.
///
/// Änderungen laufen über [UndoableCommand]s durch die [history],
/// dadurch sind Undo und Redo ohne State-Snapshots möglich.
class CounterController extends FeatureController {
  CounterController({
    required CounterRepository repository,
    required SettingsController settings,
    required HapticsService haptics,
  }) : _repository = repository,
       _settings = settings,
       _haptics = haptics;

  final CounterRepository _repository;
  final SettingsController _settings;
  final HapticsService _haptics;

  Map<String, int> counters = Map<String, int>.from(
    CounterRepository.defaultCounters,
  );
  String currentCounter = CounterRepository.defaultCurrentCounter;
  Map<String, List<String>> counterHistory = {};
  DateTime roundStartedAt = DateTime.now();

  bool get negativeEnabled => _settings.counterNegativeEnabled;

  @override
  Future<void> load() async {
    final data = await _repository.load();
    counters = data.counters;
    currentCounter = data.currentCounter;
    counterHistory = data.history;
    roundStartedAt = DateTime.now();
    isLoading = false;
  }

  void increment() {
    _changeScore(currentCounter, counters[currentCounter]! + 1, 'erhöht');
  }

  void decrement() {
    if (!CounterHelper.canDecrement(
      score: counters[currentCounter]!,
      allowNegative: negativeEnabled,
    )) {
      return;
    }
    _changeScore(currentCounter, counters[currentCounter]! - 1, 'verringert');
  }

  void reset() {
    final score = counters[currentCounter]!;
    if (score == 0) {
      return;
    }
    _changeScore(currentCounter, 0, 'zurückgesetzt');
  }

  /// Setzt alle Zähler auf 0 (für „Partie abschließen“).
  void resetBoard({bool clearHistory = false}) {
    final hasScores = counters.values.any((value) => value != 0);
    final hasHistory = counterHistory.values.any(
      (entries) => entries.isNotEmpty,
    );
    if (!hasScores && (!clearHistory || !hasHistory)) {
      return;
    }
    final oldCounters = Map<String, int>.from(counters);
    final oldHistory = Map<String, List<String>>.from(counterHistory);
    _pushUndoable(
      () {
        counters = Map<String, int>.from(counters)
          ..updateAll((key, value) => 0);
        if (clearHistory) {
          counterHistory = {};
        }
        roundStartedAt = DateTime.now();
        notifyListeners();
        unawaited(_persist());
      },
      revert: () {
        counters = oldCounters;
        counterHistory = oldHistory;
        notifyListeners();
        unawaited(_persist());
      },
    );
  }

  void _changeScore(String counterName, int newValue, String action) {
    final oldValue = counters[counterName]!;
    final changeTime = DateTime.now();
    _pushUndoable(
      () {
        _applyScoreChange(
          counterName,
          newValue,
          '${HistoryUtils.formatTime(changeTime)} - $action.',
          recordEntry: true,
        );
      },
      revert: () {
        _applyScoreChange(
          counterName,
          oldValue,
          '${HistoryUtils.formatTime(changeTime)} - $action.',
          recordEntry: false,
        );
      },
    );
    unawaited(_haptics.light());
  }

  /// Wendet eine Punktänderung direkt an (ohne Undo-Verlauf).
  void _applyScoreChange(
    String counterName,
    int newValue,
    String? entry, {
    required bool recordEntry,
  }) {
    counters = Map<String, int>.from(counters)..[counterName] = newValue;
    if (entry != null) {
      counterHistory = recordEntry
          ? CounterHelper.recordHistory(
              history: counterHistory,
              counterName: counterName,
              entry: entry,
            )
          : _removeFirstHistoryEntry(counterHistory, counterName, entry);
    }
    notifyListeners();
    unawaited(_persist());
  }

  static Map<String, List<String>> _removeFirstHistoryEntry(
    Map<String, List<String>> history,
    String counterName,
    String entry,
  ) {
    final entries = history[counterName] ?? const <String>[];
    if (!entries.contains(entry)) {
      return history;
    }
    final next = List<String>.from(entries)..remove(entry);
    return Map<String, List<String>>.from(history)..[counterName] = next;
  }

  void selectCounter(String counter) {
    if (currentCounter == counter || !counters.containsKey(counter)) {
      return;
    }
    _mutate(() => currentCounter = counter);
  }

  void addCounter(String counterName) {
    final result = CounterHelper.addCounter(
      counters: counters,
      counterName: counterName,
    );
    final oldCurrent = currentCounter;
    _pushUndoable(
      () {
        counters = result.counters;
        currentCounter = result.currentCounter;
      },
      revert: () {
        counters = LinkedHashMap<String, int>.from(counters)
          ..remove(counterName);
        currentCounter = oldCurrent;
      },
    );
    unawaited(_haptics.light());
  }

  void renameCounter(String oldName, String newName) {
    final result = CounterHelper.renameCounter(
      counters: counters,
      history: counterHistory,
      currentCounter: currentCounter,
      oldName: oldName,
      newName: newName,
    );
    final oldCounters = Map<String, int>.from(counters);
    final oldHistory = Map<String, List<String>>.from(counterHistory);
    final oldCurrent = currentCounter;
    _pushUndoable(
      () {
        counters = result.counters;
        counterHistory = result.history;
        currentCounter = result.currentCounter;
      },
      revert: () {
        counters = oldCounters;
        counterHistory = oldHistory;
        currentCounter = oldCurrent;
      },
    );
    unawaited(_haptics.light());
  }

  void deleteCounter(String counterName) {
    if (counters.length <= 1) {
      return;
    }
    final result = CounterHelper.deleteCounter(
      counters: counters,
      history: counterHistory,
      currentCounter: currentCounter,
      counterName: counterName,
    );
    final oldCounters = Map<String, int>.from(counters);
    final oldHistory = Map<String, List<String>>.from(counterHistory);
    _pushUndoable(
      () {
        counters = result.counters;
        counterHistory = result.history;
        currentCounter = result.currentCounter;
      },
      revert: () {
        counters = oldCounters;
        counterHistory = oldHistory;
        currentCounter = counterName;
      },
    );
    unawaited(_haptics.light());
  }

  void reorderCounters(int oldIndex, int newIndex) {
    final reordered = CounterHelper.reorderCounters(
      counters,
      oldIndex,
      newIndex,
    );
    if (reordered == null) {
      return;
    }
    final original = LinkedHashMap<String, int>.from(counters);
    _pushUndoable(
      () => counters = reordered,
      revert: () => counters = original,
    );
    unawaited(_haptics.light());
  }

  void setHistoryEnabled(bool enabled) {
    _settings.setCounterHistoryEnabled(enabled);
  }

  void setNegativeEnabled(bool enabled) {
    _settings.setCounterNegativeEnabled(enabled);
  }

  /// Führt eine Änderung über den Undo-Verlauf aus.
  void _pushUndoable(void Function() apply, {void Function()? revert}) {
    history.execute(
      CallbackCommand(applyChange: apply, revertChange: revert ?? apply),
    );
  }

  void _mutate(void Function() change) {
    change();
    notifyListeners();
    unawaited(_persist());
  }

  Future<void> _persist() {
    return _repository.save(
      counters: counters,
      currentCounter: currentCounter,
      history: counterHistory,
    );
  }
}
