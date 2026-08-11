import 'package:shared_preferences/shared_preferences.dart';

/// Eine einzelne, deterministische Speichermigration.
///
/// Migrationen laufen in aufsteigender Reihenfolge: Eine Migration wird
/// ausgeführt, wenn der aktuelle Schema-Stand ihrem [fromVersion] entspricht.
/// Danach wird der Stand auf [toVersion] gesetzt.
abstract class AppMigration {
  int get fromVersion;
  int get toVersion;

  Future<void> run(SharedPreferences prefs);
}
