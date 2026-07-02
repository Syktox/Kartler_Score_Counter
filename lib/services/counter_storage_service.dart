import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_mode.dart';
import '../models/game_rules.dart';
import '../models/watten_game.dart';

class CounterStorageData {
  final Map<String, int> counters;
  final String currentCounter;
  final Map<String, WattenGame> wattenGames;
  final String currentWattenGame;
  final Map<String, int> mulatschakPlayers;
  final String currentMulatschakPlayer;
  final Map<String, int> hosnObePlayers;
  final String currentHosnObePlayer;
  final int mulatschakMultiplier;
  final bool muleqackEnabled;
  final int muleqackTriggerPoints;
  final int muleqackResetPoints;
  final bool counterHistoryEnabled;
  final bool counterNegativeEnabled;
  final Map<String, List<String>> counterHistory;
  final bool mulatschakHistoryEnabled;
  final List<String> mulatschakHistory;
  final int mulatschakHistoryRound;
  final List<String> mulatschakRoundPlayers;
  final AppMode appMode;

  const CounterStorageData({
    required this.counters,
    required this.currentCounter,
    required this.wattenGames,
    required this.currentWattenGame,
    required this.mulatschakPlayers,
    required this.currentMulatschakPlayer,
    required this.hosnObePlayers,
    required this.currentHosnObePlayer,
    required this.mulatschakMultiplier,
    required this.muleqackEnabled,
    required this.muleqackTriggerPoints,
    required this.muleqackResetPoints,
    required this.counterHistoryEnabled,
    required this.counterNegativeEnabled,
    required this.counterHistory,
    required this.mulatschakHistoryEnabled,
    required this.mulatschakHistory,
    required this.mulatschakHistoryRound,
    required this.mulatschakRoundPlayers,
    required this.appMode,
  });
}

class CounterStorageService {
  static const String _countersKey = 'counters';
  static const String _currentCounterKey = 'current_counter';
  static const String _wattenGamesKey = 'watten_games';
  static const String _currentWattenGameKey = 'current_watten_game';
  static const String _mulatschakPlayersKey = 'mulatschak_players';
  static const String _currentMulatschakPlayerKey = 'current_mulatschak_player';
  static const String _hosnObePlayersKey = 'hosn_obe_players';
  static const String _currentHosnObePlayerKey = 'current_hosn_obe_player';
  static const String _mulatschakMultiplierKey = 'mulatschak_multiplier';
  static const String _muleqackEnabledKey = 'muleqack_enabled';
  static const String _muleqackTriggerPointsKey = 'muleqack_trigger_points';
  static const String _muleqackResetPointsKey = 'muleqack_reset_points';
  static const String _counterHistoryEnabledKey = 'counter_history_enabled';
  static const String _counterNegativeEnabledKey = 'counter_negative_enabled';
  static const String _counterHistoryKey = 'counter_history';
  static const String _mulatschakHistoryEnabledKey =
      'mulatschak_history_enabled';
  static const String _mulatschakHistoryKey = 'mulatschak_history';
  static const String _mulatschakHistoryRoundKey = 'mulatschak_history_round';
  static const String _mulatschakRoundPlayersKey = 'mulatschak_round_players';
  static const String _appModeKey = 'app_mode';

  static const Map<String, int> defaultCounters = {
    'Workout streak': 0,
    'Days without smoking': 0,
    'Days till my next holidays': 100,
  };
  static const String defaultCurrentCounter = 'Workout streak';
  static const Map<String, WattenGame> defaultWattenGames = {
    'Game 1': WattenGame(me: 0, you: 0),
    'Game 2': WattenGame(me: 0, you: 0),
    'Game 3': WattenGame(me: 0, you: 0),
  };
  static const String defaultCurrentWattenGame = 'Game 1';
  static const Map<String, int> defaultMulatschakPlayers = {
    'Player 1': GameRules.mulatschakStartingScore,
    'Player 2': GameRules.mulatschakStartingScore,
  };
  static const String defaultCurrentMulatschakPlayer = 'Player 1';
  static const Map<String, int> defaultHosnObePlayers = {
    'Player 1': GameRules.hosnObeStartingLives,
    'Player 2': GameRules.hosnObeStartingLives,
  };
  static const String defaultCurrentHosnObePlayer = 'Player 1';
  static const int defaultMulatschakMultiplier = 1;
  static const bool defaultMuleqackEnabled = false;
  static const int defaultMuleqackTriggerPoints = 100;
  static const int defaultMuleqackResetPoints = 50;
  static const bool defaultCounterHistoryEnabled = false;
  static const bool defaultCounterNegativeEnabled = false;
  static const bool defaultMulatschakHistoryEnabled = false;
  static const int defaultMulatschakHistoryRound = 1;
  static const AppMode defaultAppMode = AppMode.counter;

  static Future<CounterStorageData> load() async {
    final prefs = await SharedPreferences.getInstance();
    final countersJson = prefs.getString(_countersKey);
    final storedCurrentCounter = prefs.getString(_currentCounterKey);
    final wattenGamesJson = prefs.getString(_wattenGamesKey);
    final storedCurrentWattenGame = prefs.getString(_currentWattenGameKey);
    final mulatschakPlayersJson = prefs.getString(_mulatschakPlayersKey);
    final storedCurrentMulatschakPlayer = prefs.getString(
      _currentMulatschakPlayerKey,
    );
    final hosnObePlayersJson = prefs.getString(_hosnObePlayersKey);
    final storedCurrentHosnObePlayer = prefs.getString(
      _currentHosnObePlayerKey,
    );
    final storedMulatschakMultiplier = prefs.getInt(_mulatschakMultiplierKey);
    final storedMuleqackEnabled = prefs.getBool(_muleqackEnabledKey);
    final storedMuleqackTriggerPoints = prefs.getInt(_muleqackTriggerPointsKey);
    final storedMuleqackResetPoints = prefs.getInt(_muleqackResetPointsKey);
    final storedCounterHistoryEnabled = prefs.getBool(
      _counterHistoryEnabledKey,
    );
    final storedCounterNegativeEnabled = prefs.getBool(
      _counterNegativeEnabledKey,
    );
    final storedMulatschakHistoryEnabled = prefs.getBool(
      _mulatschakHistoryEnabledKey,
    );
    final storedMulatschakHistoryRound = prefs.getInt(
      _mulatschakHistoryRoundKey,
    );
    final storedAppMode = prefs.getString(_appModeKey);

    final counters = _decodeCounters(countersJson);
    final wattenGames = _decodeWattenGames(wattenGamesJson);
    final mulatschakPlayers = _decodeCounters(
      mulatschakPlayersJson,
      fallback: defaultMulatschakPlayers,
    );
    final hosnObePlayers = _decodeCounters(
      hosnObePlayersJson,
      fallback: defaultHosnObePlayers,
    );
    final currentCounter = counters.containsKey(storedCurrentCounter)
        ? storedCurrentCounter!
        : counters.keys.first;
    final currentWattenGame = wattenGames.containsKey(storedCurrentWattenGame)
        ? storedCurrentWattenGame!
        : wattenGames.keys.first;
    final currentMulatschakPlayer =
        mulatschakPlayers.containsKey(storedCurrentMulatschakPlayer)
        ? storedCurrentMulatschakPlayer!
        : mulatschakPlayers.keys.first;
    final currentHosnObePlayer =
        hosnObePlayers.containsKey(storedCurrentHosnObePlayer)
        ? storedCurrentHosnObePlayer!
        : hosnObePlayers.keys.first;
    final appMode = _decodeAppMode(storedAppMode);
    final mulatschakMultiplier =
        storedMulatschakMultiplier != null && storedMulatschakMultiplier > 0
        ? storedMulatschakMultiplier
        : defaultMulatschakMultiplier;
    final muleqackEnabled = storedMuleqackEnabled ?? defaultMuleqackEnabled;
    final muleqackTriggerPoints =
        storedMuleqackTriggerPoints != null && storedMuleqackTriggerPoints > 0
        ? storedMuleqackTriggerPoints
        : defaultMuleqackTriggerPoints;
    final muleqackResetPoints =
        storedMuleqackResetPoints != null && storedMuleqackResetPoints >= 0
        ? storedMuleqackResetPoints
        : defaultMuleqackResetPoints;
    final counterHistoryEnabled =
        storedCounterHistoryEnabled ?? defaultCounterHistoryEnabled;
    final counterNegativeEnabled =
        storedCounterNegativeEnabled ?? defaultCounterNegativeEnabled;
    final counterHistory = _loadCounterHistory(prefs, currentCounter);
    final mulatschakHistoryEnabled =
        storedMulatschakHistoryEnabled ?? defaultMulatschakHistoryEnabled;
    final mulatschakHistory = _decodeStringList(
      prefs.getString(_mulatschakHistoryKey),
    );
    final mulatschakHistoryRound =
        storedMulatschakHistoryRound != null && storedMulatschakHistoryRound > 0
        ? storedMulatschakHistoryRound
        : defaultMulatschakHistoryRound;
    final mulatschakRoundPlayers = _decodeStringList(
      prefs.getString(_mulatschakRoundPlayersKey),
    ).where(mulatschakPlayers.containsKey).toList(growable: false);

    return CounterStorageData(
      counters: counters,
      currentCounter: currentCounter,
      wattenGames: wattenGames,
      currentWattenGame: currentWattenGame,
      mulatschakPlayers: mulatschakPlayers,
      currentMulatschakPlayer: currentMulatschakPlayer,
      hosnObePlayers: hosnObePlayers,
      currentHosnObePlayer: currentHosnObePlayer,
      mulatschakMultiplier: mulatschakMultiplier,
      muleqackEnabled: muleqackEnabled,
      muleqackTriggerPoints: muleqackTriggerPoints,
      muleqackResetPoints: muleqackResetPoints,
      counterHistoryEnabled: counterHistoryEnabled,
      counterNegativeEnabled: counterNegativeEnabled,
      counterHistory: counterHistory,
      mulatschakHistoryEnabled: mulatschakHistoryEnabled,
      mulatschakHistory: mulatschakHistory,
      mulatschakHistoryRound: mulatschakHistoryRound,
      mulatschakRoundPlayers: mulatschakRoundPlayers,
      appMode: appMode,
    );
  }

  static Future<void> save({
    required Map<String, int> counters,
    required String currentCounter,
    required Map<String, WattenGame> wattenGames,
    required String currentWattenGame,
    required Map<String, int> mulatschakPlayers,
    required String currentMulatschakPlayer,
    required Map<String, int> hosnObePlayers,
    required String currentHosnObePlayer,
    required int mulatschakMultiplier,
    required bool muleqackEnabled,
    required int muleqackTriggerPoints,
    required int muleqackResetPoints,
    required bool counterHistoryEnabled,
    required bool counterNegativeEnabled,
    required Map<String, List<String>> counterHistory,
    required bool mulatschakHistoryEnabled,
    required List<String> mulatschakHistory,
    required int mulatschakHistoryRound,
    required List<String> mulatschakRoundPlayers,
    required AppMode appMode,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_countersKey, jsonEncode(counters));
    await prefs.setString(_currentCounterKey, currentCounter);
    await prefs.setString(
      _wattenGamesKey,
      jsonEncode(
        wattenGames.map((key, value) => MapEntry(key, value.toJson())),
      ),
    );
    await prefs.setString(_currentWattenGameKey, currentWattenGame);
    await prefs.setString(_mulatschakPlayersKey, jsonEncode(mulatschakPlayers));
    await prefs.setString(_currentMulatschakPlayerKey, currentMulatschakPlayer);
    await prefs.setString(_hosnObePlayersKey, jsonEncode(hosnObePlayers));
    await prefs.setString(_currentHosnObePlayerKey, currentHosnObePlayer);
    await prefs.setInt(_mulatschakMultiplierKey, mulatschakMultiplier);
    await prefs.setBool(_muleqackEnabledKey, muleqackEnabled);
    await prefs.setInt(_muleqackTriggerPointsKey, muleqackTriggerPoints);
    await prefs.setInt(_muleqackResetPointsKey, muleqackResetPoints);
    await prefs.setBool(_counterHistoryEnabledKey, counterHistoryEnabled);
    await prefs.setBool(_counterNegativeEnabledKey, counterNegativeEnabled);
    await prefs.setString(_counterHistoryKey, jsonEncode(counterHistory));
    await prefs.setBool(_mulatschakHistoryEnabledKey, mulatschakHistoryEnabled);
    await prefs.setString(_mulatschakHistoryKey, jsonEncode(mulatschakHistory));
    await prefs.setInt(_mulatschakHistoryRoundKey, mulatschakHistoryRound);
    await prefs.setString(
      _mulatschakRoundPlayersKey,
      jsonEncode(mulatschakRoundPlayers),
    );
    await prefs.setString(_appModeKey, appMode.name);
  }

  static List<String> _decodeStringList(String? listJson) {
    if (listJson == null || listJson.isEmpty) {
      return <String>[];
    }

    try {
      final decoded = jsonDecode(listJson);
      if (decoded is List) {
        return decoded.whereType<String>().toList(growable: false);
      }
    } catch (_) {
      return <String>[];
    }

    return <String>[];
  }

  static Map<String, List<String>> _loadCounterHistory(
    SharedPreferences prefs,
    String currentCounter,
  ) {
    try {
      return _decodeCounterHistory(prefs.getString(_counterHistoryKey));
    } on TypeError {
      return _decodeLegacyCounterHistory(
        prefs.getStringList(_counterHistoryKey),
        currentCounter,
      );
    }
  }

  static Map<String, List<String>> _decodeLegacyCounterHistory(
    List<String>? history,
    String currentCounter,
  ) {
    if (history == null || history.isEmpty) {
      return <String, List<String>>{};
    }

    return <String, List<String>>{currentCounter: List<String>.from(history)};
  }

  static Map<String, List<String>> _decodeCounterHistory(String? historyJson) {
    if (historyJson == null || historyJson.isEmpty) {
      return <String, List<String>>{};
    }

    try {
      final decoded = jsonDecode(historyJson);
      if (decoded is! Map<String, dynamic>) {
        return <String, List<String>>{};
      }

      return decoded.map((key, value) {
        if (value is List) {
          return MapEntry(
            key,
            value.whereType<String>().toList(growable: false),
          );
        }
        return MapEntry(key, <String>[]);
      });
    } catch (_) {
      return <String, List<String>>{};
    }
  }

  static Map<String, int> _decodeCounters(
    String? countersJson, {
    Map<String, int>? fallback,
  }) {
    final fallbackCounters = fallback ?? defaultCounters;

    if (countersJson == null || countersJson.isEmpty) {
      return Map<String, int>.from(fallbackCounters);
    }

    try {
      final decoded = jsonDecode(countersJson);
      if (decoded is! Map<String, dynamic>) {
        return Map<String, int>.from(fallbackCounters);
      }

      final counters = decoded.map(
        (key, value) => MapEntry(key, (value as num).toInt()),
      );

      if (counters.isEmpty) {
        return Map<String, int>.from(fallbackCounters);
      }

      return counters;
    } catch (_) {
      return Map<String, int>.from(fallbackCounters);
    }
  }

  static Map<String, WattenGame> _decodeWattenGames(String? wattenGamesJson) {
    if (wattenGamesJson == null || wattenGamesJson.isEmpty) {
      return Map<String, WattenGame>.from(defaultWattenGames);
    }

    try {
      final decoded = jsonDecode(wattenGamesJson);
      if (decoded is! Map<String, dynamic>) {
        return Map<String, WattenGame>.from(defaultWattenGames);
      }

      final games = decoded.map((key, value) {
        if (value is! Map<String, dynamic>) {
          return MapEntry(
            _normalizeWattenGameName(key),
            const WattenGame(me: 0, you: 0),
          );
        }
        return MapEntry(
          _normalizeWattenGameName(key),
          WattenGame.fromJson(value),
        );
      });

      if (games.isEmpty) {
        return Map<String, WattenGame>.from(defaultWattenGames);
      }

      return games;
    } catch (_) {
      return Map<String, WattenGame>.from(defaultWattenGames);
    }
  }

  static AppMode _decodeAppMode(String? storedAppMode) {
    return AppMode.values.firstWhere(
      (mode) => mode.name == storedAppMode,
      orElse: () => defaultAppMode,
    );
  }

  static String _normalizeWattenGameName(String name) {
    if (name == 'Spiel 1') {
      return 'Game 1';
    }
    return name;
  }
}
