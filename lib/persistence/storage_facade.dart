import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'migrations/app_migration.dart';
import 'migrations/v1_player_migration.dart';
import 'migrations/v2_rule_profile_migration.dart';
import 'schema.dart';
import 'storage_keys.dart';

/// Zentrale Initialisierung der lokalen Speicherung.
///
/// [init] muss genau einmal vor dem Laden von Daten aufgerufen werden.
/// Es führt ausstehende Migrationen in aufsteigender Reihenfolge aus und
/// schreibt danach die aktuelle Schema-Version.
class AppStorage {
  AppStorage._();

  static final List<AppMigration> migrations = [
    V1PlayerMigration(),
    V2RuleProfileMigration(),
  ];

  /// Für Tests: die Migrationen als geordnete Kette.
  @visibleForTesting
  static List<AppMigration> get orderedMigrations => List.of(migrations);

  static Future<SharedPreferences> init() async {
    final prefs = await SharedPreferences.getInstance();
    var version = prefs.getInt(StorageKeys.schemaVersion) ?? 0;

    for (final migration in migrations) {
      if (version != migration.fromVersion) {
        continue;
      }
      await migration.run(prefs);
      version = migration.toVersion;
      await prefs.setInt(StorageKeys.schemaVersion, version);
    }

    if (version > StorageSchema.current) {
      // Neuere Daten als die App kennt: nicht anfassen, nur die Version
      // merken und mit den Defaults arbeiten.
      version = StorageSchema.current;
    }

    return prefs;
  }
}
