import 'dart:convert';

/// Robuste JSON-Hilfsfunktionen für die Speicher-Schicht.
/// Fehlerhafte Daten führen nie zu Abstürzen, sondern zu sicheren Defaults.
class JsonCodec {
  const JsonCodec._();

  static Object? decode(String? json) {
    if (json == null || json.isEmpty) {
      return null;
    }
    try {
      return jsonDecode(json);
    } catch (_) {
      return null;
    }
  }

  static Map<String, dynamic>? decodeMap(String? json) {
    final decoded = decode(json);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    if (decoded is Map) {
      return Map<String, dynamic>.from(decoded);
    }
    return null;
  }

  static List<T>? decodeList<T>(
    String? json,
    T Function(Object? item) convert,
  ) {
    final decoded = decode(json);
    if (decoded is! List) {
      return null;
    }
    return decoded.map(convert).toList(growable: false);
  }

  static String encode(Object? value) {
    return jsonEncode(value);
  }
}
