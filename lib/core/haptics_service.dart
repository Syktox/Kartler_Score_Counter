import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Dezentes haptisches Feedback mit Abschalt-Option.
///
/// Auf Desktop- und Web-Plattformen ist Haptik nicht verfügbar; dort werden
/// alle Aufrufe zu No-Ops, damit keine Fehler entstehen.
class HapticsService {
  HapticsService({required this.isEnabled, this.lightImpact, this.heavyImpact});

  /// Liefert zur Laufzeit, ob Haptik aktuell aktiviert ist (Einstellung).
  final bool Function() isEnabled;

  /// Überschreibbar für Tests.
  final Future<void> Function()? lightImpact;
  final Future<void> Function()? heavyImpact;

  static bool get supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  /// Leichtes Feedback für normale Punkteänderungen.
  Future<void> light() async {
    if (!supported || !isEnabled()) {
      return;
    }
    try {
      await (lightImpact ?? HapticFeedback.lightImpact)();
    } catch (_) {
      // Haptik ist optional – Fehler niemals weiterreichen.
    }
  }

  /// Stärkeres Feedback für wichtige Aktionen (Sieg, Partieende).
  Future<void> heavy() async {
    if (!supported || !isEnabled()) {
      return;
    }
    try {
      await (heavyImpact ?? HapticFeedback.heavyImpact)();
    } catch (_) {
      // Haptik ist optional – Fehler niemals weiterreichen.
    }
  }
}
