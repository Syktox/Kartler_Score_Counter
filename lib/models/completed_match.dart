import 'app_mode.dart';

/// Eine abgeschlossene Partie in strukturierter Form.
///
/// Aus diesen Daten werden Statistiken berechnet, daher werden Gewinner und
/// Endstände maschinell lesbar gespeichert. Für Modi ohne globale Spieler
/// (Watten, Freier Zähler) können die Teilnehmer über [winnerLabel] bzw.
/// die [finalStandings] mit Sprechnamen abgebildet werden.
class CompletedMatch {
  final String id;
  final String? sessionId;
  final AppMode gameType;
  final List<String> participantIds;
  final String? winnerId;
  final String? winnerLabel;
  final DateTime startedAt;
  final DateTime endedAt;
  final Map<String, int> finalStandings;

  const CompletedMatch({
    required this.id,
    this.sessionId,
    required this.gameType,
    required this.participantIds,
    this.winnerId,
    this.winnerLabel,
    required this.startedAt,
    required this.endedAt,
    required this.finalStandings,
  });

  String get winnerName => winnerId ?? winnerLabel ?? '—';

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sessionId': sessionId,
      'gameType': gameType.name,
      'participants': participantIds,
      'winnerId': winnerId,
      'winnerLabel': winnerLabel,
      'startedAt': startedAt.toIso8601String(),
      'endedAt': endedAt.toIso8601String(),
      'standings': finalStandings,
    };
  }

  static CompletedMatch? fromJson(Map<String, dynamic> json) {
    final gameType = AppMode.values.where(
      (mode) => mode.name == json['gameType'],
    );
    if (gameType.isEmpty) {
      return null;
    }
    final standingsJson = json['standings'];
    if (standingsJson is! Map) {
      return null;
    }
    final startedAt = DateTime.tryParse(json['startedAt'] as String? ?? '');
    final endedAt = DateTime.tryParse(json['endedAt'] as String? ?? '');
    if (startedAt == null || endedAt == null) {
      return null;
    }

    return CompletedMatch(
      id: json['id'] as String,
      sessionId: json['sessionId'] as String?,
      gameType: gameType.single,
      participantIds: (json['participants'] as List? ?? const [])
          .whereType<String>()
          .toList(growable: false),
      winnerId: json['winnerId'] as String?,
      winnerLabel: json['winnerLabel'] as String?,
      startedAt: startedAt,
      endedAt: endedAt,
      finalStandings: standingsJson.map(
        (key, value) => MapEntry(key as String, (value as num).toInt()),
      ),
    );
  }
}
