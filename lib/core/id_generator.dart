import 'dart:math';

/// Erzeugt stabile, kollisionsarme IDs ohne externe Abhängigkeiten.
class IdGenerator {
  const IdGenerator._();

  static final Random _random = Random();

  static String newId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
    final randomPart = _random.nextInt(0x7fffffff).toRadixString(36);
    return 'p_$timestamp$randomPart';
  }
}
