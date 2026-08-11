/// Ein rückgängig machbarer Befehl im Command-Muster.
///
/// [apply] wendet die Änderung an, [revert] macht sie rückgängig.
/// Kommandos halten bewusst nur die nötigen Vorher-/Nachher-Werte
/// (z. B. `ScoreChanged`), statt komplette State-Snapshots zu kopieren.
abstract class UndoableCommand {
  void apply();

  void revert();
}
