class WinnerText {
  const WinnerText._();

  static bool hasMultipleWinners(String winner) {
    return winner.contains('&');
  }

  static String verbFor(String winner) {
    return hasMultipleWinners(winner) ? 'gewinnen' : 'gewinnt';
  }

  static String sentence(String winner, {bool exclamation = true}) {
    final punctuation = exclamation ? '!' : '';
    return '$winner ${verbFor(winner)}$punctuation';
  }
}
