import 'dart:convert';

/// Ein globaler Spieler, der in mehreren Spielmodi wiederverwendet werden kann.
class Player {
  final String id;
  final String name;
  final String? emoji;
  final DateTime createdAt;

  const Player({
    required this.id,
    required this.name,
    this.emoji,
    required this.createdAt,
  });

  /// [name] und [emoji] werden nur übernommen, wenn sie nicht null sind.
  /// Zum Entfernen des Emojis siehe [withEmojiRemoved].
  Player copyWith({String? name, String? emoji}) {
    return Player(
      id: id,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      createdAt: createdAt,
    );
  }

  Player withEmojiRemoved() {
    return Player(id: id, name: name, emoji: null, createdAt: createdAt);
  }

  String get displayName {
    final cleanedEmoji = emoji?.trim() ?? '';
    return cleanedEmoji.isEmpty ? name : '$cleanedEmoji $name';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'emoji': emoji,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  static Player fromJson(Map<String, dynamic> json) {
    final emoji = json['emoji'];
    return Player(
      id: json['id'] as String? ?? _fallbackId(json),
      name: json['name'] as String? ?? 'Spieler',
      emoji: emoji is String && emoji.isNotEmpty ? emoji : null,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  static String _fallbackId(Map<String, dynamic> json) {
    final name = json['name'] as String? ?? 'spieler';
    return jsonEncode({'name': name, 'fallback': true});
  }

  @override
  bool operator ==(Object other) {
    return other is Player &&
        other.id == id &&
        other.name == name &&
        other.emoji == emoji;
  }

  @override
  int get hashCode => Object.hash(id, name, emoji);
}
