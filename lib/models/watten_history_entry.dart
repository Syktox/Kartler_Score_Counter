import 'dart:convert';

import 'watten_side.dart';

/// Ein Punkteschritt im Watten-Spielstand.
class WattenHistoryEntry {
  final String time;
  final WattenSide side;
  final int points;

  const WattenHistoryEntry({
    required this.time,
    required this.side,
    required this.points,
  });

  String encode() {
    return jsonEncode({'time': time, 'side': side.name, 'points': points});
  }

  static WattenHistoryEntry? decode(String entry) {
    try {
      final decoded = jsonDecode(entry);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }
      final time = decoded['time'];
      final sideName = decoded['side'];
      final points = decoded['points'];
      final side = WattenSide.values.where((side) => side.name == sideName);

      if (time is String && points is int && side.isNotEmpty) {
        return WattenHistoryEntry(time: time, side: side.first, points: points);
      }
    } catch (_) {
      return null;
    }
    return null;
  }
}
