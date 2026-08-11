/// Ein Spielabend: ein Zeitraum, in dem mehrere Partien gespielt werden.
class GameSession {
  final String id;
  final DateTime startTime;
  final DateTime? endTime;
  final List<String> participantIds;
  final List<String> matchIds;

  const GameSession({
    required this.id,
    required this.startTime,
    this.endTime,
    required this.participantIds,
    this.matchIds = const [],
  });

  bool get isActive => endTime == null;

  GameSession copyWith({
    DateTime? startTime,
    DateTime? endTime,
    List<String>? participantIds,
    List<String>? matchIds,
  }) {
    return GameSession(
      id: id,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      participantIds: participantIds ?? this.participantIds,
      matchIds: matchIds ?? this.matchIds,
    );
  }

  GameSession withMatchRecorded(String matchId) {
    return copyWith(matchIds: [...matchIds, matchId]);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'participants': participantIds,
      'matches': matchIds,
    };
  }

  static GameSession fromJson(Map<String, dynamic> json) {
    return GameSession(
      id: json['id'] as String,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: json['endTime'] == null
          ? null
          : DateTime.tryParse(json['endTime'] as String),
      participantIds: (json['participants'] as List? ?? const [])
          .whereType<String>()
          .toList(growable: false),
      matchIds: (json['matches'] as List? ?? const [])
          .whereType<String>()
          .toList(growable: false),
    );
  }
}
