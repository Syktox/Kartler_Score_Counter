import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/rule_profile.dart';
import '../../models/app_mode.dart';
import '../json_codec.dart';
import '../storage_keys.dart';

/// Allgemeine App-Einstellungen.
class SettingsRepository {
  const SettingsRepository();

  Future<ThemeMode> loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(StorageKeys.themeMode);
    return ThemeMode.values.firstWhere(
      (mode) => mode.name == stored,
      orElse: () => ThemeMode.system,
    );
  }

  Future<void> saveThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(StorageKeys.themeMode, mode.name);
  }

  Future<bool> loadHapticsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(StorageKeys.hapticsEnabled) ?? true;
  }

  Future<void> saveHapticsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(StorageKeys.hapticsEnabled, enabled);
  }

  Future<bool> loadOnboardingCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(StorageKeys.onboardingCompleted) ?? false;
  }

  Future<void> saveOnboardingCompleted(bool completed) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(StorageKeys.onboardingCompleted, completed);
  }

  Future<bool> loadWattenTableMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(StorageKeys.wattenTableMode) ?? false;
  }

  Future<void> saveWattenTableMode(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(StorageKeys.wattenTableMode, enabled);
  }

  Future<AppMode> loadAppMode() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(StorageKeys.appMode);
    return AppMode.values.firstWhere(
      (mode) => mode.name == stored,
      orElse: () => AppMode.watten,
    );
  }

  Future<void> saveAppMode(AppMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(StorageKeys.appMode, mode.name);
  }

  Future<RuleProfile> loadRuleProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final json = JsonCodec.decodeMap(prefs.getString(StorageKeys.ruleProfile));
    if (json == null) {
      return const RuleProfile.defaults();
    }
    return RuleProfile.fromJson(json);
  }

  Future<void> saveRuleProfile(RuleProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      StorageKeys.ruleProfile,
      JsonCodec.encode(profile.toJson()),
    );
  }

  Future<bool> loadCounterHistoryEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(StorageKeys.counterHistoryEnabled) ?? false;
  }

  Future<void> saveCounterHistoryEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(StorageKeys.counterHistoryEnabled, enabled);
  }

  Future<bool> loadCounterNegativeEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(StorageKeys.counterNegativeEnabled) ?? false;
  }

  Future<void> saveCounterNegativeEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(StorageKeys.counterNegativeEnabled, enabled);
  }

  Future<bool> loadMulatschakHistoryEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(StorageKeys.mulatschakHistoryEnabled) ?? false;
  }

  Future<void> saveMulatschakHistoryEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(StorageKeys.mulatschakHistoryEnabled, enabled);
  }
}
