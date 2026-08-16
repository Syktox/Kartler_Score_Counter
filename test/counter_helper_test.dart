import 'dart:collection';

import 'package:flutter_test/flutter_test.dart';
import 'package:kartler/features/counter/counter_helper.dart';

void main() {
  group('CounterHelper.canDecrement', () {
    test('returns false at zero when negatives are disabled', () {
      expect(
        CounterHelper.canDecrement(score: 0, allowNegative: false),
        isFalse,
      );
    });

    test('returns true at zero when negatives are enabled', () {
      expect(CounterHelper.canDecrement(score: 0, allowNegative: true), isTrue);
    });

    test('returns true for positive scores', () {
      expect(
        CounterHelper.canDecrement(score: 1, allowNegative: false),
        isTrue,
      );
      expect(CounterHelper.canDecrement(score: 1, allowNegative: true), isTrue);
    });

    test('returns true for negative scores', () {
      expect(
        CounterHelper.canDecrement(score: -5, allowNegative: true),
        isTrue,
      );
    });
  });

  group('CounterHelper.recordHistory', () {
    test('creates the history list for an unknown counter', () {
      final result = CounterHelper.recordHistory(
        history: const {},
        counterName: 'Punkte',
        entry: '10:00 - erhöht.',
      );

      expect(result['Punkte'], ['10:00 - erhöht.']);
    });

    test('prepends new entries and preserves older ones', () {
      final result = CounterHelper.recordHistory(
        history: const {
          'Punkte': ['10:01 - erhöht.'],
        },
        counterName: 'Punkte',
        entry: '10:02 - erhöht.',
      );

      expect(result['Punkte'], ['10:02 - erhöht.', '10:01 - erhöht.']);
    });

    test('keeps histories of other counters intact', () {
      final result = CounterHelper.recordHistory(
        history: const {
          'Runden': ['eintrag'],
        },
        counterName: 'Punkte',
        entry: 'neu',
      );

      expect(result['Runden'], ['eintrag']);
    });

    test('does not mutate the input history', () {
      final history = <String, List<String>>{
        'Punkte': ['alt'],
      };

      CounterHelper.recordHistory(
        history: history,
        counterName: 'Punkte',
        entry: 'neu',
      );

      expect(history['Punkte'], ['alt']);
    });
  });

  group('CounterHelper.updateScore', () {
    test('updates the score and records the entry', () {
      final result = CounterHelper.updateScore(
        counters: const {'Punkte': 3},
        history: const {},
        currentCounter: 'Punkte',
        score: 7,
        entry: '10:00 - erhöht.',
      );

      expect(result.counters['Punkte'], 7);
      expect(result.history['Punkte'], ['10:00 - erhöht.']);
    });

    test('does not mutate the input maps', () {
      final counters = <String, int>{'Punkte': 3};
      final history = <String, List<String>>{};

      CounterHelper.updateScore(
        counters: counters,
        history: history,
        currentCounter: 'Punkte',
        score: 0,
        entry: '10:00 - zurückgesetzt.',
      );

      expect(counters['Punkte'], 3);
      expect(history, isEmpty);
    });
  });

  group('CounterHelper.addCounter', () {
    test('adds a new counter with score zero and selects it', () {
      final result = CounterHelper.addCounter(
        counters: const {'Punkte': 3},
        counterName: 'Runden',
      );

      expect(result.counters, {'Punkte': 3, 'Runden': 0});
      expect(result.currentCounter, 'Runden');
    });
  });

  group('CounterHelper.renameCounter', () {
    final counters = <String, int>{'Punkte': 3, 'Runden': 0};
    final history = <String, List<String>>{
      'Punkte': ['10:00 - erhöht.'],
    };

    test('renames counters, history and the selected counter', () {
      final result = CounterHelper.renameCounter(
        counters: counters,
        history: history,
        currentCounter: 'Punkte',
        oldName: 'Punkte',
        newName: 'Lese-Tage',
      );

      expect(result.counters, containsPair('Lese-Tage', 3));
      expect(result.counters, isNot(contains('Punkte')));
      expect(result.history['Lese-Tage'], ['10:00 - erhöht.']);
      expect(result.currentCounter, 'Lese-Tage');
    });

    test('keeps the selection when renaming an unselected counter', () {
      final result = CounterHelper.renameCounter(
        counters: counters,
        history: history,
        currentCounter: 'Punkte',
        oldName: 'Runden',
        newName: 'Spiele',
      );

      expect(result.currentCounter, 'Punkte');
      expect(result.counters, containsPair('Spiele', 0));
    });

    test('can swap the rename back to the original state', () {
      final renamed = CounterHelper.renameCounter(
        counters: counters,
        history: history,
        currentCounter: 'Punkte',
        oldName: 'Punkte',
        newName: 'Lese-Tage',
      );
      final reverted = CounterHelper.renameCounter(
        counters: renamed.counters,
        history: renamed.history,
        currentCounter: renamed.currentCounter,
        oldName: 'Lese-Tage',
        newName: 'Punkte',
      );

      expect(reverted.counters, counters);
      expect(reverted.history, history);
      expect(reverted.currentCounter, 'Punkte');
    });
  });

  group('CounterHelper.deleteCounter', () {
    test('removes the counter and selects the first remaining one', () {
      final result = CounterHelper.deleteCounter(
        counters: const {'Punkte': 3, 'Runden': 0},
        history: const {
          'Punkte': ['eintrag'],
        },
        currentCounter: 'Punkte',
        counterName: 'Punkte',
      );

      expect(result.counters, {'Runden': 0});
      expect(result.history, isNot(contains('Punkte')));
      expect(result.currentCounter, 'Runden');
    });

    test('keeps the selection when deleting an unselected counter', () {
      final result = CounterHelper.deleteCounter(
        counters: const {'Punkte': 3, 'Runden': 0},
        history: const {},
        currentCounter: 'Punkte',
        counterName: 'Runden',
      );

      expect(result.counters, {'Punkte': 3});
      expect(result.currentCounter, 'Punkte');
    });
  });

  group('CounterHelper.reorderCounters', () {
    test('moves a counter forward with index adjustment', () {
      final result = CounterHelper.reorderCounters(
        LinkedHashMap<String, int>.from({'A': 1, 'B': 2, 'C': 3}),
        0,
        2,
      );

      expect(result, isNotNull);
      expect(result!.keys.toList(), ['B', 'A', 'C']);
    });

    test('moves a counter backward', () {
      final result = CounterHelper.reorderCounters(
        LinkedHashMap<String, int>.from({'A': 1, 'B': 2, 'C': 3}),
        2,
        0,
      );

      expect(result, isNotNull);
      expect(result!.keys.toList(), ['C', 'A', 'B']);
    });

    test('returns null for invalid indices', () {
      final counters = LinkedHashMap<String, int>.from({'A': 1, 'B': 2});

      expect(CounterHelper.reorderCounters(counters, -1, 1), isNull);
      expect(CounterHelper.reorderCounters(counters, 2, 0), isNull);
      expect(CounterHelper.reorderCounters(counters, 0, 1), isNull);
    });
  });
}
