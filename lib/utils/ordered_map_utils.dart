import 'dart:collection';

class OrderedMapUtils {
  const OrderedMapUtils._();

  static LinkedHashMap<String, T> renameKey<T>(
    Map<String, T> values,
    String oldName,
    String newName, {
    T Function(T value)? copyValue,
  }) {
    return LinkedHashMap<String, T>.fromEntries(
      values.entries.map((entry) {
        final key = entry.key == oldName ? newName : entry.key;
        final value = copyValue == null ? entry.value : copyValue(entry.value);

        return MapEntry(key, value);
      }),
    );
  }

  static LinkedHashMap<String, T>? reorder<T>(
    Map<String, T> values,
    int oldIndex,
    int newIndex,
  ) {
    final entries = values.entries.toList();
    if (oldIndex < 0 || oldIndex >= entries.length) {
      return null;
    }

    var targetIndex = newIndex;
    if (targetIndex > oldIndex) {
      targetIndex -= 1;
    }
    if (targetIndex < 0 ||
        targetIndex >= entries.length ||
        targetIndex == oldIndex) {
      return null;
    }

    final movedEntry = entries.removeAt(oldIndex);
    entries.insert(targetIndex, movedEntry);

    return LinkedHashMap<String, T>.fromEntries(entries);
  }
}
