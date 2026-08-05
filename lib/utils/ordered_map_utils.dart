import 'dart:collection';

class OrderedMapUtils {
  const OrderedMapUtils._();

  static ({LinkedHashMap<String, T> values, String selectedKey})
  renameSelectedKey<T>({
    required Map<String, T> values,
    required String selectedKey,
    required String oldKey,
    required String newKey,
    T Function(T value)? copyValue,
  }) {
    if (!values.containsKey(oldKey)) {
      return (
        values: renameKey(values, oldKey, newKey, copyValue: copyValue),
        selectedKey: selectedKey,
      );
    }

    return (
      values: renameKey(values, oldKey, newKey, copyValue: copyValue),
      selectedKey: selectedKey == oldKey ? newKey : selectedKey,
    );
  }

  static ({LinkedHashMap<String, T> values, String selectedKey})
  removeSelectedKey<T>({
    required Map<String, T> values,
    required String selectedKey,
    required String key,
  }) {
    if (!values.containsKey(key)) {
      return (
        values: LinkedHashMap<String, T>.from(values),
        selectedKey: selectedKey,
      );
    }
    if (values.length <= 1) {
      throw StateError('Cannot remove the last key with a non-null selection.');
    }

    final nextValues = LinkedHashMap<String, T>.from(values)..remove(key);

    return (
      values: nextValues,
      selectedKey: selectedKey == key ? nextValues.keys.first : selectedKey,
    );
  }

  static LinkedHashMap<String, T> renameKey<T>(
    Map<String, T> values,
    String oldName,
    String newName, {
    T Function(T value)? copyValue,
  }) {
    if (!values.containsKey(oldName)) {
      return LinkedHashMap<String, T>.from(values);
    }
    if (oldName != newName && values.containsKey(newName)) {
      throw ArgumentError.value(
        newName,
        'newName',
        'Cannot rename to an existing key.',
      );
    }

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
