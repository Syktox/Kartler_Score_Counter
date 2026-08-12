import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../models/rule_profile.dart';
import '../migrations/app_migration.dart';
import '../storage_keys.dart';

/// Schema 1 → 2: Regelprofil.
///
/// Fasst die bisherigen einzelnen Muleqack-Einstellungs-Keys in einem
/// `rule_profile`-JSON zusammen. Fehlende Werte werden durch die
/// Standardwerte ersetzt.
class V2RuleProfileMigration implements AppMigration {
  @override
  int get fromVersion => 1;

  @override
  int get toVersion => 2;

  @override
  Future<void> run(SharedPreferences prefs) async {
    const defaults = RuleProfile.defaults();

    final profile = RuleProfile(
      wattenWinningScore: defaults.wattenWinningScore,
      mulatschakStartingScore: defaults.mulatschakStartingScore,
      hosnObeStartingLives: defaults.hosnObeStartingLives,
      muleqackEnabled:
          prefs.getBool(LegacyStorageKeys.muleqackEnabled) ??
          defaults.muleqackEnabled,
      muleqackTriggerPoints: _positiveInt(
        prefs.getInt(LegacyStorageKeys.muleqackTriggerPoints),
        defaults.muleqackTriggerPoints,
      ),
      muleqackResetPoints: _nonNegativeInt(
        prefs.getInt(LegacyStorageKeys.muleqackResetPoints),
        defaults.muleqackResetPoints,
      ),
      mulatschakAutoCompleteRound: defaults.mulatschakAutoCompleteRound,
    );

    await prefs.setString(
      StorageKeys.ruleProfile,
      jsonEncode(profile.toJson()),
    );

    await prefs.remove(LegacyStorageKeys.muleqackEnabled);
    await prefs.remove(LegacyStorageKeys.muleqackTriggerPoints);
    await prefs.remove(LegacyStorageKeys.muleqackResetPoints);
  }

  static int _positiveInt(int? value, int fallback) {
    return value != null && value > 0 ? value : fallback;
  }

  static int _nonNegativeInt(int? value, int fallback) {
    return value != null && value >= 0 ? value : fallback;
  }
}
