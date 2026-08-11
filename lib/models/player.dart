import 'dart:convert';

/// Ein globaler Spieler, der in mehreren Spielmodi wiederverwendet werden kann.
class Player {
  final String id;
  final String name;
  final DateTime createdAt;

  const Player({required this.id, required this.name, required this.createdAt});

  Player copyWith({String? name}) {
    return Player(id: id, name: name ?? this.name, createdAt: createdAt);
  }

  String get displayName => name;

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'createdAt': createdAt.toIso8601String()};
  }

  static Player fromJson(Map<String, dynamic> json) {
    return Player(
      id: json['id'] as String? ?? _fallbackId(json),
      name: json['name'] as String? ?? 'Spieler',
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  static String _fallbackId(Map<String, dynamic> json) {
    final name = json['name'] as String? ?? 'spieler';
    return jsonEncode({'name': name, 'fallback': true});
  }

  @override
  bool operator ==(Object other) {
    return other is Player && other.id == id && other.name == name;
  }

  @override
  int get hashCode => Object.hash(id, name);
}
