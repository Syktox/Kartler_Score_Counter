import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/app_mode.dart';
import '../../models/rule_profile.dart';
import '../../persistence/repositories/settings_repository.dart';
import '../feature_controller.dart';

/// Allgemeine App-Einstellungen: Theme, Haptik, Onboarding, Verlauf-Toggles,
/// Regelprofil und der zuletzt verwendete Spielmodus.
class SettingsController extends FeatureController {
  SettingsController({required SettingsRepository repository})
    : _repository = repository;

  final SettingsRepository _repository;

  ThemeMode themeMode = ThemeMode.system;
  bool hapticsEnabled = true;
  bool onboardingCompleted = false;
  bool wattenTableMode = false;
  AppMode appMode = AppMode.watten;
  bool counterHistoryEnabled = false;
  bool counterNegativeEnabled = false;
  bool mulatschakHistoryEnabled = false;
  RuleProfile ruleProfile = const RuleProfile.defaults();

  @override
  Future<void> load() async {
    themeMode = await _repository.loadThemeMode();
    hapticsEnabled = await _repository.loadHapticsEnabled();
    onboardingCompleted = await _repository.loadOnboardingCompleted();
    wattenTableMode = await _repository.loadWattenTableMode();
    appMode = await _repository.loadAppMode();
    counterHistoryEnabled = await _repository.loadCounterHistoryEnabled();
    counterNegativeEnabled = await _repository.loadCounterNegativeEnabled();
    mulatschakHistoryEnabled =
        await _repository.loadMulatschakHistoryEnabled();
    ruleProfile = await _repository.loadRuleProfile();
    isLoading = false;
  }

  void setThemeMode(ThemeMode mode) {
    if (themeMode == mode) {
      return;
    }
    themeMode = mode;
    notifyListeners();
    unawaited(_repository.saveThemeMode(mode));
  }

  void setHapticsEnabled(bool enabled) {
    if (hapticsEnabled == enabled) {
      return;
    }
    hapticsEnabled = enabled;
    notifyListeners();
    unawaited(_repository.saveHapticsEnabled(enabled));
  }

  void setOnboardingCompleted() {
    if (onboardingCompleted) {
      return;
    }
    onboardingCompleted = true;
    notifyListeners();
    unawaited(_repository.saveOnboardingCompleted(true));
  }

  void setWattenTableMode(bool enabled) {
    if (wattenTableMode == enabled) {
      return;
    }
    wattenTableMode = enabled;
    notifyListeners();
    unawaited(_repository.saveWattenTableMode(enabled));
  }

  void setAppMode(AppMode mode) {
    if (appMode == mode) {
      return;
    }
    appMode = mode;
    notifyListeners();
    unawaited(_repository.saveAppMode(mode));
  }

  void setCounterHistoryEnabled(bool enabled) {
    if (counterHistoryEnabled == enabled) {
      return;
    }
    counterHistoryEnabled = enabled;
    notifyListeners();
    unawaited(_repository.saveCounterHistoryEnabled(enabled));
  }

  void setCounterNegativeEnabled(bool enabled) {
    if (counterNegativeEnabled == enabled) {
      return;
    }
    counterNegativeEnabled = enabled;
    notifyListeners();
    unawaited(_repository.saveCounterNegativeEnabled(enabled));
  }

  void setMulatschakHistoryEnabled(bool enabled) {
    if (mulatschakHistoryEnabled == enabled) {
      return;
    }
    mulatschakHistoryEnabled = enabled;
    notifyListeners();
    unawaited(_repository.saveMulatschakHistoryEnabled(enabled));
  }

  void setRuleProfile(RuleProfile profile) {
    ruleProfile = profile;
    notifyListeners();
    unawaited(_repository.saveRuleProfile(profile));
  }

  void resetRuleProfile() {
    setRuleProfile(const RuleProfile.defaults());
  }
}
