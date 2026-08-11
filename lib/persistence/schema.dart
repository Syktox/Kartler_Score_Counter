/// Versionierung des lokalen Datenmodells.
///
/// Schema 0: historischer Stand (alle Daten in flachen Legacy-Keys,
/// Spieler nur mode-intern).
/// Schema 1: globale Spieler mit stabilen IDs, Lineups pro Modus.
/// Schema 2: Regelprofil (`rule_profile`) ersetzt einzelne Muleqack-Keys.
abstract final class StorageSchema {
  static const int current = 2;
}
