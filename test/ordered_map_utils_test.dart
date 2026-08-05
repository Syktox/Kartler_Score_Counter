import 'package:flutter_test/flutter_test.dart';
import 'package:kartler/utils/ordered_map_utils.dart';

void main() {
  group('OrderedMapUtils', () {
    test(
      'renameSelectedKey updates the selection when selected key is renamed',
      () {
        final result = OrderedMapUtils.renameSelectedKey<int>(
          values: {'A': 1, 'B': 2},
          selectedKey: 'A',
          oldKey: 'A',
          newKey: 'C',
        );

        expect(result.values, {'C': 1, 'B': 2});
        expect(result.selectedKey, 'C');
      },
    );

    test('removeSelectedKey selects the first remaining key after removal', () {
      final result = OrderedMapUtils.removeSelectedKey<int>(
        values: {'A': 1, 'B': 2},
        selectedKey: 'A',
        key: 'A',
      );

      expect(result.values, {'B': 2});
      expect(result.selectedKey, 'B');
    });

    test('renameSelectedKey keeps selection when the old key is missing', () {
      final result = OrderedMapUtils.renameSelectedKey<int>(
        values: {'A': 1, 'B': 2},
        selectedKey: 'Missing',
        oldKey: 'Missing',
        newKey: 'C',
      );

      expect(result.values, {'A': 1, 'B': 2});
      expect(result.selectedKey, 'Missing');
    });

    test('renameSelectedKey rejects existing new keys', () {
      expect(
        () => OrderedMapUtils.renameSelectedKey<int>(
          values: {'A': 1, 'B': 2},
          selectedKey: 'A',
          oldKey: 'A',
          newKey: 'B',
        ),
        throwsArgumentError,
      );
    });

    test('removeSelectedKey keeps selection when the key is missing', () {
      final result = OrderedMapUtils.removeSelectedKey<int>(
        values: {'A': 1, 'B': 2},
        selectedKey: 'A',
        key: 'Missing',
      );

      expect(result.values, {'A': 1, 'B': 2});
      expect(result.selectedKey, 'A');
    });

    test('removeSelectedKey rejects removing the last key', () {
      expect(
        () => OrderedMapUtils.removeSelectedKey<int>(
          values: {'A': 1},
          selectedKey: 'A',
          key: 'A',
        ),
        throwsStateError,
      );
    });
  });
}
