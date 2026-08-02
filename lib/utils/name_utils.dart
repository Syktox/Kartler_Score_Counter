class NameUtils {
  const NameUtils._();

  static String clean(String name) {
    return name.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  static bool isUnique(String name, Iterable<String> existingNames) {
    final normalizedName = _normalize(name);

    return normalizedName.isNotEmpty &&
        !existingNames.map(_normalize).contains(normalizedName);
  }

  static bool isUniqueExcept(
    String name,
    Iterable<String> existingNames,
    String ignoredName,
  ) {
    final normalizedName = _normalize(name);
    final normalizedIgnoredName = _normalize(ignoredName);

    return normalizedName.isNotEmpty &&
        !existingNames
            .where((existingName) {
              return _normalize(existingName) != normalizedIgnoredName;
            })
            .map(_normalize)
            .contains(normalizedName);
  }

  static String _normalize(String name) {
    return clean(name).toLowerCase();
  }
}
