import 'dart:convert';

class MulatschakHistoryEntry {
  final int round;
  final String time;
  final String playerName;
  final int points;

  const MulatschakHistoryEntry({
    required this.round,
    required this.time,
    required this.playerName,
    required this.points,
  });

  String encode() {
    return jsonEncode({
      'round': round,
      'time': time,
      'player': playerName,
      'points': points,
    });
  }

  static MulatschakHistoryEntry? decode(String entry) {
    try {
      final decoded = jsonDecode(entry);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }

      final round = decoded['round'];
      final time = decoded['time'];
      final playerName = decoded['player'];
      final points = decoded['points'];

      if (round is int &&
          time is String &&
          playerName is String &&
          points is int) {
        return MulatschakHistoryEntry(
          round: round,
          time: time,
          playerName: playerName,
          points: points,
        );
      }
    } catch (_) {
      return null;
    }

    return null;
  }
}
