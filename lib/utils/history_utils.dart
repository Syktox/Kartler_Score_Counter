class HistoryUtils {
  const HistoryUtils._();

  static Map<String, List<String>> copyCounterHistory(
    Map<String, List<String>> history,
  ) {
    return history.map(
      (counterName, entries) =>
          MapEntry(counterName, List<String>.from(entries)),
    );
  }

  static String formatTime(DateTime time) {
    String twoDigits(int value) => value.toString().padLeft(2, '0');

    return '${twoDigits(time.hour)}:${twoDigits(time.minute)}:${twoDigits(time.second)}';
  }

  static String formatSignedPoints(int points) {
    return points > 0 ? '+$points' : '$points';
  }
}
