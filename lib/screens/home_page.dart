import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:collection';
import '../models/app_mode.dart';
import '../models/game_rules.dart';
import '../models/watten_game.dart';
import '../services/counter_storage_service.dart';
import '../widgets/counter_controls.dart';
import '../widgets/counter_drawer.dart';
import '../widgets/score_button.dart';
import '../widgets/score_card.dart';
import '../widgets/winner_banner.dart';
import 'settings_page.dart';

enum WattenSide { me, you }

class _HomePageSnapshot {
  final Map<String, int> counters;
  final String currentCounter;
  final Map<String, WattenGame> wattenGames;
  final String currentWattenGame;
  final WattenSide selectedWattenSide;
  final Map<String, int> mulatschakPlayers;
  final String currentMulatschakPlayer;
  final Map<String, int> hosnObePlayers;
  final String currentHosnObePlayer;
  final int mulatschakMultiplier;
  final bool muleqackEnabled;
  final int muleqackTriggerPoints;
  final int muleqackResetPoints;
  final bool counterHistoryEnabled;
  final Map<String, List<String>> counterHistory;
  final bool mulatschakHistoryEnabled;
  final List<String> mulatschakHistory;
  final int mulatschakHistoryRound;
  final Set<String> mulatschakRoundPlayers;
  final AppMode appMode;

  const _HomePageSnapshot({
    required this.counters,
    required this.currentCounter,
    required this.wattenGames,
    required this.currentWattenGame,
    required this.selectedWattenSide,
    required this.mulatschakPlayers,
    required this.currentMulatschakPlayer,
    required this.hosnObePlayers,
    required this.currentHosnObePlayer,
    required this.mulatschakMultiplier,
    required this.muleqackEnabled,
    required this.muleqackTriggerPoints,
    required this.muleqackResetPoints,
    required this.counterHistoryEnabled,
    required this.counterHistory,
    required this.mulatschakHistoryEnabled,
    required this.mulatschakHistory,
    required this.mulatschakHistoryRound,
    required this.mulatschakRoundPlayers,
    required this.appMode,
  });
}

class _MulatschakHistoryEntry {
  final int round;
  final String time;
  final String playerName;
  final int points;

  const _MulatschakHistoryEntry({
    required this.round,
    required this.time,
    required this.playerName,
    required this.points,
  });
}

class HomePage extends StatefulWidget {
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final AppMode appMode;
  final ValueChanged<AppMode> onAppModeChanged;

  const HomePage({
    super.key,
    required this.themeMode,
    required this.onThemeModeChanged,
    required this.appMode,
    required this.onAppModeChanged,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const int _maxUndoSnapshots = 40;

  Map<String, int> counters = Map<String, int>.from(
    CounterStorageService.defaultCounters,
  );
  String currentCounter = CounterStorageService.defaultCurrentCounter;
  Map<String, WattenGame> wattenGames = Map<String, WattenGame>.from(
    CounterStorageService.defaultWattenGames,
  );
  String currentWattenGame = CounterStorageService.defaultCurrentWattenGame;
  WattenSide selectedWattenSide = WattenSide.me;
  Map<String, int> mulatschakPlayers = Map<String, int>.from(
    CounterStorageService.defaultMulatschakPlayers,
  );
  String currentMulatschakPlayer =
      CounterStorageService.defaultCurrentMulatschakPlayer;
  Map<String, int> hosnObePlayers = Map<String, int>.from(
    CounterStorageService.defaultHosnObePlayers,
  );
  String currentHosnObePlayer =
      CounterStorageService.defaultCurrentHosnObePlayer;
  int mulatschakMultiplier = CounterStorageService.defaultMulatschakMultiplier;
  bool muleqackEnabled = CounterStorageService.defaultMuleqackEnabled;
  int muleqackTriggerPoints =
      CounterStorageService.defaultMuleqackTriggerPoints;
  int muleqackResetPoints = CounterStorageService.defaultMuleqackResetPoints;
  bool counterHistoryEnabled =
      CounterStorageService.defaultCounterHistoryEnabled;
  Map<String, List<String>> counterHistory = {};
  bool mulatschakHistoryEnabled =
      CounterStorageService.defaultMulatschakHistoryEnabled;
  List<String> mulatschakHistory = [];
  int mulatschakHistoryRound =
      CounterStorageService.defaultMulatschakHistoryRound;
  Set<String> mulatschakRoundPlayers = {};
  final Map<AppMode, List<_HomePageSnapshot>> _undoStacks = {
    for (final mode in AppMode.values) mode: <_HomePageSnapshot>[],
  };
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isLoadingCounters = true;

  @override
  void initState() {
    super.initState();
    _loadCounters();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadCounters() async {
    final storedData = await CounterStorageService.load();
    if (!mounted) {
      return;
    }

    widget.onAppModeChanged(storedData.appMode);
    setState(() {
      counters = storedData.counters;
      currentCounter = storedData.currentCounter;
      wattenGames = storedData.wattenGames;
      currentWattenGame = storedData.currentWattenGame;
      mulatschakPlayers = storedData.mulatschakPlayers;
      currentMulatschakPlayer = storedData.currentMulatschakPlayer;
      hosnObePlayers = storedData.hosnObePlayers;
      currentHosnObePlayer = storedData.currentHosnObePlayer;
      mulatschakMultiplier = storedData.mulatschakMultiplier;
      muleqackEnabled = storedData.muleqackEnabled;
      muleqackTriggerPoints = storedData.muleqackTriggerPoints;
      muleqackResetPoints = storedData.muleqackResetPoints;
      counterHistoryEnabled = storedData.counterHistoryEnabled;
      counterHistory = _copyCounterHistory(storedData.counterHistory);
      mulatschakHistoryEnabled = storedData.mulatschakHistoryEnabled;
      mulatschakHistory = List<String>.from(storedData.mulatschakHistory);
      mulatschakHistoryRound = storedData.mulatschakHistoryRound;
      mulatschakRoundPlayers = Set<String>.from(
        storedData.mulatschakRoundPlayers,
      );
      _isLoadingCounters = false;
    });
  }

  Future<void> _saveCounters({AppMode? appMode}) {
    return CounterStorageService.save(
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
      counterHistory: counterHistory,
      mulatschakHistoryEnabled: mulatschakHistoryEnabled,
      mulatschakHistory: mulatschakHistory,
      mulatschakHistoryRound: mulatschakHistoryRound,
      mulatschakRoundPlayers: mulatschakRoundPlayers.toList(),
      appMode: appMode ?? widget.appMode,
    );
  }

  _HomePageSnapshot _createSnapshot() {
    return _HomePageSnapshot(
      counters: LinkedHashMap<String, int>.from(counters),
      currentCounter: currentCounter,
      wattenGames: LinkedHashMap<String, WattenGame>.from(wattenGames),
      currentWattenGame: currentWattenGame,
      selectedWattenSide: selectedWattenSide,
      mulatschakPlayers: LinkedHashMap<String, int>.from(mulatschakPlayers),
      currentMulatschakPlayer: currentMulatschakPlayer,
      hosnObePlayers: LinkedHashMap<String, int>.from(hosnObePlayers),
      currentHosnObePlayer: currentHosnObePlayer,
      mulatschakMultiplier: mulatschakMultiplier,
      muleqackEnabled: muleqackEnabled,
      muleqackTriggerPoints: muleqackTriggerPoints,
      muleqackResetPoints: muleqackResetPoints,
      counterHistoryEnabled: counterHistoryEnabled,
      counterHistory: _copyCounterHistory(counterHistory),
      mulatschakHistoryEnabled: mulatschakHistoryEnabled,
      mulatschakHistory: List<String>.from(mulatschakHistory),
      mulatschakHistoryRound: mulatschakHistoryRound,
      mulatschakRoundPlayers: Set<String>.from(mulatschakRoundPlayers),
      appMode: widget.appMode,
    );
  }

  List<_HomePageSnapshot> get _currentUndoStack => _undoStacks[widget.appMode]!;

  void _pushUndoSnapshot() {
    final undoStack = _currentUndoStack;
    undoStack.add(_createSnapshot());
    if (undoStack.length > _maxUndoSnapshots) {
      undoStack.removeAt(0);
    }
  }

  void _undoLastAction() {
    final undoStack = _currentUndoStack;
    if (undoStack.isEmpty) {
      return;
    }

    final snapshot = undoStack.removeLast();
    setState(() {
      _restoreSnapshotForCurrentMode(snapshot);
    });
    _saveCounters();
  }

  void _restoreSnapshotForCurrentMode(_HomePageSnapshot snapshot) {
    switch (widget.appMode) {
      case AppMode.counter:
        counters = LinkedHashMap<String, int>.from(snapshot.counters);
        currentCounter = snapshot.currentCounter;
        counterHistoryEnabled = snapshot.counterHistoryEnabled;
        counterHistory = _copyCounterHistory(snapshot.counterHistory);
      case AppMode.watten:
        wattenGames = LinkedHashMap<String, WattenGame>.from(
          snapshot.wattenGames,
        );
        currentWattenGame = snapshot.currentWattenGame;
        selectedWattenSide = snapshot.selectedWattenSide;
      case AppMode.mulatschak:
        mulatschakPlayers = LinkedHashMap<String, int>.from(
          snapshot.mulatschakPlayers,
        );
        currentMulatschakPlayer = snapshot.currentMulatschakPlayer;
        mulatschakMultiplier = snapshot.mulatschakMultiplier;
        muleqackEnabled = snapshot.muleqackEnabled;
        muleqackTriggerPoints = snapshot.muleqackTriggerPoints;
        muleqackResetPoints = snapshot.muleqackResetPoints;
        mulatschakHistoryEnabled = snapshot.mulatschakHistoryEnabled;
        mulatschakHistory = List<String>.from(snapshot.mulatschakHistory);
        mulatschakHistoryRound = snapshot.mulatschakHistoryRound;
        mulatschakRoundPlayers = Set<String>.from(
          snapshot.mulatschakRoundPlayers,
        );
      case AppMode.hosnObe:
        hosnObePlayers = LinkedHashMap<String, int>.from(
          snapshot.hosnObePlayers,
        );
        currentHosnObePlayer = snapshot.currentHosnObePlayer;
    }
  }

  void _handleAppModeChanged(AppMode mode) {
    if (mode == widget.appMode) {
      return;
    }

    widget.onAppModeChanged(mode);
    _saveCounters(appMode: mode);
  }

  void _increment() {
    _pushUndoSnapshot();
    setState(() {
      counters[currentCounter] = counters[currentCounter]! + 1;
      _recordCounterHistory('increased');
    });
    _saveCounters();
  }

  void _decrement() {
    if (counters[currentCounter]! <= 0) {
      return;
    }

    _pushUndoSnapshot();
    setState(() {
      counters[currentCounter] = counters[currentCounter]! - 1;
      _recordCounterHistory('decreased');
    });
    _saveCounters();
  }

  void _reset() {
    if (counters[currentCounter] == 0) {
      return;
    }

    _pushUndoSnapshot();
    setState(() {
      counters[currentCounter] = 0;
      _recordCounterHistory('reseted');
    });
    _saveCounters();
  }

  void _recordCounterHistory(String action) {
    if (!counterHistoryEnabled) {
      return;
    }

    final currentHistory = counterHistory[currentCounter] ?? const <String>[];
    counterHistory = Map<String, List<String>>.from(counterHistory)
      ..[currentCounter] = [
        '${_formatHistoryTime(DateTime.now())} - $action.',
        ...currentHistory,
      ];
  }

  Map<String, List<String>> _copyCounterHistory(
    Map<String, List<String>> history,
  ) {
    return history.map(
      (counterName, entries) =>
          MapEntry(counterName, List<String>.from(entries)),
    );
  }

  String _formatHistoryTime(DateTime time) {
    String twoDigits(int value) => value.toString().padLeft(2, '0');

    return '${twoDigits(time.hour)}:${twoDigits(time.minute)}:${twoDigits(time.second)}';
  }

  String _formatSignedPoints(int points) {
    return points > 0 ? '+$points' : '$points';
  }

  String _encodeMulatschakHistoryEntry(_MulatschakHistoryEntry entry) {
    return jsonEncode({
      'round': entry.round,
      'time': entry.time,
      'player': entry.playerName,
      'points': entry.points,
    });
  }

  _MulatschakHistoryEntry? _decodeMulatschakHistoryEntry(String entry) {
    try {
      final decoded = jsonDecode(entry);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }

      final round = decoded['round'];
      final time = decoded['time'];
      final playerName = decoded['player'];
      final points = decoded['points'];

      if (round is int &&
          time is String &&
          playerName is String &&
          points is int) {
        return _MulatschakHistoryEntry(
          round: round,
          time: time,
          playerName: playerName,
          points: points,
        );
      }
    } catch (_) {
      return null;
    }

    return null;
  }

  void _recordMulatschakHistory(String playerName, int points) {
    if (!mulatschakHistoryEnabled || points == 0) {
      return;
    }

    mulatschakHistory = [
      ...mulatschakHistory,
      _encodeMulatschakHistoryEntry(
        _MulatschakHistoryEntry(
          round: mulatschakHistoryRound,
          time: _formatHistoryTime(DateTime.now()),
          playerName: playerName,
          points: points,
        ),
      ),
    ];

    mulatschakRoundPlayers = Set<String>.from(mulatschakRoundPlayers)
      ..add(playerName);
    if (mulatschakRoundPlayers.length >= mulatschakPlayers.length) {
      mulatschakHistoryRound += 1;
      mulatschakRoundPlayers = {};
    }
  }

  void _selectCounter(String counter) {
    if (currentCounter == counter) {
      return;
    }

    setState(() {
      currentCounter = counter;
    });
    _saveCounters();
  }

  bool _isCounterNameValid(String counterName) {
    return _isUniqueName(counterName, counters.keys);
  }

  bool _isWattenGameNameValid(String gameName) {
    return _isUniqueName(gameName, wattenGames.keys);
  }

  bool _isMulatschakPlayerNameValid(String playerName) {
    return _isUniqueName(playerName, mulatschakPlayers.keys);
  }

  bool _isHosnObePlayerNameValid(String playerName) {
    return _isUniqueName(playerName, hosnObePlayers.keys);
  }

  bool _isUniqueName(String name, Iterable<String> existingNames) {
    final normalizedName = _normalizeName(name);
    return normalizedName.isNotEmpty &&
        !existingNames.map(_normalizeName).contains(normalizedName);
  }

  bool _isUniqueNameExcept(
    String name,
    Iterable<String> existingNames,
    String ignoredName,
  ) {
    final normalizedName = _normalizeName(name);
    final normalizedIgnoredName = _normalizeName(ignoredName);
    return normalizedName.isNotEmpty &&
        !existingNames
            .where((existingName) {
              return _normalizeName(existingName) != normalizedIgnoredName;
            })
            .map(_normalizeName)
            .contains(normalizedName);
  }

  String _normalizeName(String name) {
    return _cleanName(name).toLowerCase();
  }

  String _cleanName(String name) {
    return name.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  String? _wattenWinner(WattenGame game) {
    return GameRules.wattenWinner(game);
  }

  String? _mulatschakWinner() {
    return GameRules.firstZeroScoreWinner(mulatschakPlayers);
  }

  String? _hosnObeWinner() {
    return GameRules.lastPlayerWithLives(hosnObePlayers);
  }

  void _addCounterToList(String counterName) {
    _pushUndoSnapshot();
    setState(() {
      counters[counterName] = 0;
      currentCounter = counterName;
    });
    _saveCounters();
  }

  void _renameCounter(String oldName, String newName) {
    _pushUndoSnapshot();
    setState(() {
      counters = _renameCounterEntry(counters, oldName, newName);
      counterHistory = _renameHistoryEntry(counterHistory, oldName, newName);
      if (currentCounter == oldName) {
        currentCounter = newName;
      }
    });
    _saveCounters();
  }

  void _deleteCounter(String counterName) {
    if (counters.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('At least one counter must remain.')),
      );
      return;
    }

    _pushUndoSnapshot();
    setState(() {
      counters.remove(counterName);
      counterHistory = Map<String, List<String>>.from(counterHistory)
        ..remove(counterName);
      if (currentCounter == counterName) {
        currentCounter = counters.keys.first;
      }
    });
    _saveCounters();
  }

  void _selectWattenGame(String gameName) {
    if (currentWattenGame == gameName) {
      return;
    }

    setState(() {
      currentWattenGame = gameName;
    });
    _saveCounters();
  }

  void _renameWattenGame(String oldName, String newName) {
    _pushUndoSnapshot();
    setState(() {
      wattenGames = LinkedHashMap<String, WattenGame>.fromEntries(
        wattenGames.entries.map((entry) {
          if (entry.key == oldName) {
            return MapEntry(newName, entry.value);
          }
          return entry;
        }),
      );
      if (currentWattenGame == oldName) {
        currentWattenGame = newName;
      }
    });
    _saveCounters();
  }

  void _renameMulatschakPlayer(String oldName, String newName) {
    _pushUndoSnapshot();
    setState(() {
      mulatschakPlayers = _renameCounterEntry(
        mulatschakPlayers,
        oldName,
        newName,
      );
      if (currentMulatschakPlayer == oldName) {
        currentMulatschakPlayer = newName;
      }
      if (mulatschakRoundPlayers.remove(oldName)) {
        mulatschakRoundPlayers = Set<String>.from(mulatschakRoundPlayers)
          ..add(newName);
      }
    });
    _saveCounters();
  }

  void _renameHosnObePlayer(String oldName, String newName) {
    _pushUndoSnapshot();
    setState(() {
      hosnObePlayers = _renameCounterEntry(hosnObePlayers, oldName, newName);
      if (currentHosnObePlayer == oldName) {
        currentHosnObePlayer = newName;
      }
    });
    _saveCounters();
  }

  LinkedHashMap<String, int> _renameCounterEntry(
    Map<String, int> values,
    String oldName,
    String newName,
  ) {
    return LinkedHashMap<String, int>.fromEntries(
      values.entries.map((entry) {
        if (entry.key == oldName) {
          return MapEntry(newName, entry.value);
        }
        return entry;
      }),
    );
  }

  LinkedHashMap<String, List<String>> _renameHistoryEntry(
    Map<String, List<String>> values,
    String oldName,
    String newName,
  ) {
    return LinkedHashMap<String, List<String>>.fromEntries(
      values.entries.map((entry) {
        if (entry.key == oldName) {
          return MapEntry(newName, List<String>.from(entry.value));
        }
        return MapEntry(entry.key, List<String>.from(entry.value));
      }),
    );
  }

  void _reorderCounters(int oldIndex, int newIndex) {
    final reordered = _reorderEntries(counters, oldIndex, newIndex);
    if (reordered == null) {
      return;
    }

    _pushUndoSnapshot();
    setState(() {
      counters = reordered;
    });
    _saveCounters();
  }

  void _reorderMulatschakPlayers(int oldIndex, int newIndex) {
    final reordered = _reorderEntries(mulatschakPlayers, oldIndex, newIndex);
    if (reordered == null) {
      return;
    }

    _pushUndoSnapshot();
    setState(() {
      mulatschakPlayers = reordered;
    });
    _saveCounters();
  }

  void _reorderHosnObePlayers(int oldIndex, int newIndex) {
    final reordered = _reorderEntries(hosnObePlayers, oldIndex, newIndex);
    if (reordered == null) {
      return;
    }

    _pushUndoSnapshot();
    setState(() {
      hosnObePlayers = reordered;
    });
    _saveCounters();
  }

  void _reorderWattenGames(int oldIndex, int newIndex) {
    final reordered = _reorderEntries(wattenGames, oldIndex, newIndex);
    if (reordered == null) {
      return;
    }

    _pushUndoSnapshot();
    setState(() {
      wattenGames = reordered;
    });
    _saveCounters();
  }

  LinkedHashMap<String, T>? _reorderEntries<T>(
    Map<String, T> values,
    int oldIndex,
    int newIndex,
  ) {
    final entries = values.entries.toList();
    if (oldIndex < 0 || oldIndex >= entries.length) {
      return null;
    }

    var targetIndex = newIndex;
    if (targetIndex > oldIndex) {
      targetIndex -= 1;
    }
    if (targetIndex < 0 ||
        targetIndex >= entries.length ||
        targetIndex == oldIndex) {
      return null;
    }

    final movedEntry = entries.removeAt(oldIndex);
    entries.insert(targetIndex, movedEntry);
    return LinkedHashMap<String, T>.fromEntries(entries);
  }

  void _addWattenGame(String gameName) {
    _pushUndoSnapshot();
    setState(() {
      wattenGames[gameName] = const WattenGame(me: 0, you: 0);
      currentWattenGame = gameName;
      selectedWattenSide = WattenSide.me;
    });
    _saveCounters();
  }

  void _deleteWattenGame(String gameName) {
    if (wattenGames.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('At least one game must remain.')),
      );
      return;
    }

    _pushUndoSnapshot();
    setState(() {
      wattenGames.remove(gameName);
      if (currentWattenGame == gameName) {
        currentWattenGame = wattenGames.keys.first;
      }
    });
    _saveCounters();
  }

  void _selectMulatschakPlayer(String playerName) {
    if (currentMulatschakPlayer == playerName) {
      return;
    }

    setState(() {
      currentMulatschakPlayer = playerName;
    });
    _saveCounters();
  }

  void _selectHosnObePlayer(String playerName) {
    if (currentHosnObePlayer == playerName) {
      return;
    }

    setState(() {
      currentHosnObePlayer = playerName;
    });
    _saveCounters();
  }

  void _addMulatschakPlayer(String playerName) {
    _pushUndoSnapshot();
    setState(() {
      mulatschakPlayers[playerName] = GameRules.mulatschakStartingScore;
      currentMulatschakPlayer = playerName;
      mulatschakRoundPlayers.remove(playerName);
    });
    _saveCounters();
  }

  void _addHosnObePlayer(String playerName) {
    _pushUndoSnapshot();
    setState(() {
      hosnObePlayers[playerName] = GameRules.hosnObeStartingLives;
      currentHosnObePlayer = playerName;
    });
    _saveCounters();
  }

  void _deleteMulatschakPlayer(String playerName) {
    if (mulatschakPlayers.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('At least one player must remain.')),
      );
      return;
    }

    _pushUndoSnapshot();
    setState(() {
      mulatschakPlayers.remove(playerName);
      mulatschakRoundPlayers.remove(playerName);
      if (mulatschakRoundPlayers.length >= mulatschakPlayers.length) {
        mulatschakHistoryRound += 1;
        mulatschakRoundPlayers = {};
      }
      if (currentMulatschakPlayer == playerName) {
        currentMulatschakPlayer = mulatschakPlayers.keys.first;
      }
    });
    _saveCounters();
  }

  void _deleteHosnObePlayer(String playerName) {
    if (hosnObePlayers.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('At least one player must remain.')),
      );
      return;
    }

    _pushUndoSnapshot();
    setState(() {
      hosnObePlayers.remove(playerName);
      if (currentHosnObePlayer == playerName) {
        currentHosnObePlayer = hosnObePlayers.keys.first;
      }
    });
    _saveCounters();
  }

  void _updateHosnObeScore(int delta) {
    final currentValue = hosnObePlayers[currentHosnObePlayer]!;
    final nextValue = currentValue + delta;

    if (nextValue < 0) {
      return;
    }

    _pushUndoSnapshot();
    setState(() {
      hosnObePlayers[currentHosnObePlayer] = nextValue;
    });
    _saveCounters();
  }

  void _resetHosnObePlayers() {
    if (hosnObePlayers.values.every(
      (value) => value == GameRules.hosnObeStartingLives,
    )) {
      return;
    }

    _pushUndoSnapshot();
    setState(() {
      hosnObePlayers.updateAll((key, value) => GameRules.hosnObeStartingLives);
    });
    _saveCounters();
  }

  void _updateMulatschakScore(int baseDelta) {
    final playerName = currentMulatschakPlayer;
    final currentValue = mulatschakPlayers[playerName]!;
    final delta = baseDelta * mulatschakMultiplier;
    final rawNextValue = currentValue + delta;

    _pushUndoSnapshot();
    final clampedNextValue = GameRules.clampAtZero(rawNextValue);
    final nextValue = muleqackEnabled
        ? _applyMuleqackReset(clampedNextValue)
        : clampedNextValue;

    setState(() {
      mulatschakPlayers[playerName] = nextValue;
      _recordMulatschakHistory(playerName, nextValue - currentValue);
    });
    _saveCounters();
  }

  int _applyMuleqackReset(int score) {
    return GameRules.applyResetLoop(
      score: score,
      triggerPoints: muleqackTriggerPoints,
      resetPoints: muleqackResetPoints,
    );
  }

  void _resetMulatschakPlayers() {
    if (mulatschakPlayers.values.every(
      (value) => value == GameRules.mulatschakStartingScore,
    )) {
      return;
    }

    _pushUndoSnapshot();
    setState(() {
      mulatschakPlayers.updateAll((playerName, value) {
        const resetValue = GameRules.mulatschakStartingScore;
        _recordMulatschakHistory(playerName, resetValue - value);
        return resetValue;
      });
    });
    _saveCounters();
  }

  void _setMulatschakMultiplier(int multiplier) {
    if (mulatschakMultiplier == multiplier) {
      return;
    }

    _pushUndoSnapshot();
    setState(() {
      mulatschakMultiplier = multiplier;
    });
    _saveCounters();
  }

  void _setMuleqackEnabled(bool enabled) {
    if (muleqackEnabled == enabled) {
      return;
    }

    _pushUndoSnapshot();
    setState(() {
      muleqackEnabled = enabled;
    });
    _saveCounters();
  }

  void _setMuleqackTriggerPoints(int points) {
    if (muleqackTriggerPoints == points) {
      return;
    }

    _pushUndoSnapshot();
    setState(() {
      muleqackTriggerPoints = points;
    });
    _saveCounters();
  }

  void _setMuleqackResetPoints(int points) {
    if (muleqackResetPoints == points) {
      return;
    }

    _pushUndoSnapshot();
    setState(() {
      muleqackResetPoints = points;
    });
    _saveCounters();
  }

  void _setCounterHistoryEnabled(bool enabled) {
    if (counterHistoryEnabled == enabled) {
      return;
    }

    _pushUndoSnapshot();
    setState(() {
      counterHistoryEnabled = enabled;
    });
    _saveCounters();
  }

  void _setMulatschakHistoryEnabled(bool enabled) {
    if (mulatschakHistoryEnabled == enabled) {
      return;
    }

    _pushUndoSnapshot();
    setState(() {
      mulatschakHistoryEnabled = enabled;
    });
    _saveCounters();
  }

  void _updateWattenScore(int delta) {
    final currentGame = wattenGames[currentWattenGame]!;
    final currentValue = selectedWattenSide == WattenSide.me
        ? currentGame.me
        : currentGame.you;
    final nextValue = currentValue + delta;

    if (nextValue < 0) {
      return;
    }

    _pushUndoSnapshot();
    setState(() {
      wattenGames[currentWattenGame] = selectedWattenSide == WattenSide.me
          ? currentGame.copyWith(me: nextValue)
          : currentGame.copyWith(you: nextValue);
    });
    _saveCounters();
  }

  Widget _buildWattenControls() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScoreButton(
              label: '+2',
              onPressed: () => _updateWattenScore(2),
              fontSize: 28,
            ),
            const SizedBox(width: 20),
            ScoreButton(
              label: '+3',
              onPressed: () => _updateWattenScore(3),
              fontSize: 28,
            ),
          ],
        ),
        const SizedBox(height: 20),
        ScoreButton(
          label: 'Reset',
          onPressed: _resetWattenSelectedSide,
          minimumSize: const Size(120, 80),
        ),
      ],
    );
  }

  void _resetWattenSelectedSide() {
    final currentGame = wattenGames[currentWattenGame]!;
    final currentValue = selectedWattenSide == WattenSide.me
        ? currentGame.me
        : currentGame.you;

    if (currentValue == 0) {
      return;
    }

    _pushUndoSnapshot();
    setState(() {
      wattenGames[currentWattenGame] = selectedWattenSide == WattenSide.me
          ? currentGame.copyWith(me: 0)
          : currentGame.copyWith(you: 0);
    });
    _saveCounters();
  }

  void _showAddCounterDialog() {
    final controller = TextEditingController();
    final focusNode = FocusNode();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        void submit() {
          final trimmedName = _cleanName(controller.text);
          if (_isCounterNameValid(trimmedName)) {
            _addCounterToList(trimmedName);
            Navigator.of(context).pop();
            return;
          }

          focusNode.requestFocus();
        }

        return AlertDialog(
          title: const Text('Add Counter'),
          content: TextField(
            controller: controller,
            focusNode: focusNode,
            autofocus: true,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => submit(),
            decoration: const InputDecoration(hintText: 'Counter name'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(onPressed: submit, child: const Text('Add')),
          ],
        );
      },
    );
  }

  void _showAddWattenGameDialog() {
    final controller = TextEditingController();
    final focusNode = FocusNode();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        void submit() {
          final trimmedName = _cleanName(controller.text);
          if (_isWattenGameNameValid(trimmedName)) {
            _addWattenGame(trimmedName);
            Navigator.of(context).pop();
            return;
          }

          focusNode.requestFocus();
        }

        return AlertDialog(
          title: const Text('Add Game'),
          content: TextField(
            controller: controller,
            focusNode: focusNode,
            autofocus: true,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => submit(),
            decoration: const InputDecoration(hintText: 'Game name'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(onPressed: submit, child: const Text('Add')),
          ],
        );
      },
    );
  }

  void _showAddMulatschakPlayerDialog() {
    _showAddPlayerDialog(
      isValidName: _isMulatschakPlayerNameValid,
      onAdd: _addMulatschakPlayer,
    );
  }

  void _showAddHosnObePlayerDialog() {
    _showAddPlayerDialog(
      isValidName: _isHosnObePlayerNameValid,
      onAdd: _addHosnObePlayer,
    );
  }

  void _showAddPlayerDialog({
    required bool Function(String playerName) isValidName,
    required ValueChanged<String> onAdd,
  }) {
    final controller = TextEditingController();
    final focusNode = FocusNode();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        void submit() {
          final trimmedName = _cleanName(controller.text);
          if (isValidName(trimmedName)) {
            onAdd(trimmedName);
            Navigator.of(context).pop();
            return;
          }

          focusNode.requestFocus();
        }

        return AlertDialog(
          title: const Text('Add Player'),
          content: TextField(
            controller: controller,
            focusNode: focusNode,
            autofocus: true,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => submit(),
            decoration: const InputDecoration(hintText: 'Player name'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(onPressed: submit, child: const Text('Add')),
          ],
        );
      },
    );
  }

  void _showRenameCounterDialog(String oldName) {
    _showRenameItemDialog(
      title: 'Rename Counter',
      initialValue: oldName,
      hintText: 'New counter name',
      duplicateNameMessage: 'This counter name can only be used once.',
      isValidName: (newName) =>
          _isUniqueNameExcept(newName, counters.keys, oldName),
      onRename: (newName) {
        if (newName != oldName) {
          _renameCounter(oldName, newName);
        }
      },
    );
  }

  void _showRenameWattenGameDialog(String oldName) {
    _showRenameItemDialog(
      title: 'Rename Game',
      initialValue: oldName,
      hintText: 'New game name',
      duplicateNameMessage: 'This game name can only be used once.',
      isValidName: (newName) =>
          _isUniqueNameExcept(newName, wattenGames.keys, oldName),
      onRename: (newName) {
        if (newName != oldName) {
          _renameWattenGame(oldName, newName);
        }
      },
    );
  }

  void _showRenameMulatschakPlayerDialog(String oldName) {
    _showRenameItemDialog(
      title: 'Rename Player',
      initialValue: oldName,
      hintText: 'New player name',
      duplicateNameMessage: 'This player name can only be used once.',
      isValidName: (newName) =>
          _isUniqueNameExcept(newName, mulatschakPlayers.keys, oldName),
      onRename: (newName) {
        if (newName != oldName) {
          _renameMulatschakPlayer(oldName, newName);
        }
      },
    );
  }

  void _showRenameHosnObePlayerDialog(String oldName) {
    _showRenameItemDialog(
      title: 'Rename Player',
      initialValue: oldName,
      hintText: 'New player name',
      duplicateNameMessage: 'This player name can only be used once.',
      isValidName: (newName) =>
          _isUniqueNameExcept(newName, hosnObePlayers.keys, oldName),
      onRename: (newName) {
        if (newName != oldName) {
          _renameHosnObePlayer(oldName, newName);
        }
      },
    );
  }

  void _showRenameItemDialog({
    required String title,
    required String initialValue,
    required String hintText,
    required String duplicateNameMessage,
    required bool Function(String newName) isValidName,
    required ValueChanged<String> onRename,
  }) {
    final focusNode = FocusNode();
    final controller = TextEditingController(text: initialValue)
      ..selection = TextSelection(
        baseOffset: 0,
        extentOffset: initialValue.length,
      );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        void submit() {
          final trimmedName = _cleanName(controller.text);
          if (trimmedName.isNotEmpty && isValidName(trimmedName)) {
            onRename(trimmedName);
            Navigator.of(context).pop();
            return;
          }

          focusNode.requestFocus();

          if (trimmedName.isNotEmpty) {
            ScaffoldMessenger.of(this.context).showSnackBar(
              SnackBar(content: Text(duplicateNameMessage)),
            );
          }
        }

        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            focusNode: focusNode,
            autofocus: true,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => submit(),
            decoration: InputDecoration(hintText: hintText),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(onPressed: submit, child: const Text('Rename')),
          ],
        );
      },
    );
  }

  void _showDeleteCounterDialog(String counterName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Counter'),
          content: Text('Do you really want to delete "$counterName"?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              autofocus: true,
              onPressed: () {
                _deleteCounter(counterName);
                Navigator.of(context).pop();
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteWattenGameDialog(String gameName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Game'),
          content: Text('Do you really want to delete "$gameName"?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _deleteWattenGame(gameName);
                Navigator.of(context).pop();
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteMulatschakPlayerDialog(String playerName) {
    _showDeletePlayerDialog(
      playerName: playerName,
      onDelete: _deleteMulatschakPlayer,
    );
  }

  void _showDeleteHosnObePlayerDialog(String playerName) {
    _showDeletePlayerDialog(
      playerName: playerName,
      onDelete: _deleteHosnObePlayer,
    );
  }

  void _showDeletePlayerDialog({
    required String playerName,
    required ValueChanged<String> onDelete,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Player'),
          content: Text('Do you really want to delete "$playerName"?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              autofocus: true,
              onPressed: () {
                onDelete(playerName);
                Navigator.of(context).pop();
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      elevation: 0,
      scrolledUnderElevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      actions: [
        if (widget.appMode == AppMode.counter && counterHistoryEnabled)
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: IconButton(
              icon: const Icon(Icons.history),
              onPressed: () {
                _scaffoldKey.currentState?.openEndDrawer();
              },
              tooltip: 'Counter history',
            ),
          ),
        if (widget.appMode == AppMode.mulatschak && mulatschakHistoryEnabled)
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: IconButton(
              icon: const Icon(Icons.history),
              onPressed: () {
                _scaffoldKey.currentState?.openEndDrawer();
              },
              tooltip: 'Mulatschak history',
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(right: 4),
          child: IconButton(
            icon: const Icon(Icons.undo),
            onPressed: _currentUndoStack.isEmpty ? null : _undoLastAction,
            tooltip: 'Undo',
          ),
        ),
      ],
    );
  }

  Widget _buildDrawer() {
    final isWattenMode = widget.appMode == AppMode.watten;
    final isMulatschakMode = widget.appMode == AppMode.mulatschak;
    final isHosnObeMode = widget.appMode == AppMode.hosnObe;
    final isPlayerMode = isMulatschakMode || isHosnObeMode;

    return CounterDrawer(
      items: isWattenMode
          ? wattenGames.keys.toList()
          : isMulatschakMode
          ? mulatschakPlayers.keys.toList()
          : isHosnObeMode
          ? hosnObePlayers.keys.toList()
          : counters.keys.toList(),
      selectedItem: isWattenMode
          ? currentWattenGame
          : isMulatschakMode
          ? currentMulatschakPlayer
          : isHosnObeMode
          ? currentHosnObePlayer
          : currentCounter,
      addButtonLabel: isWattenMode
          ? 'Add Game'
          : isPlayerMode
          ? 'Add Player'
          : 'New Counter',
      addButtonIcon: isWattenMode
          ? Icons.add
          : isPlayerMode
          ? Icons.person_add_alt_1
          : Icons.add,
      closeDrawerOnAdd: !isPlayerMode,
      enableReorder: true,
      onAddNewItem: isWattenMode
          ? _showAddWattenGameDialog
          : isMulatschakMode
          ? _showAddMulatschakPlayerDialog
          : isHosnObeMode
          ? _showAddHosnObePlayerDialog
          : _showAddCounterDialog,
      onSelectItem: (item) {
        if (isWattenMode) {
          _selectWattenGame(item);
          return;
        }
        if (isMulatschakMode) {
          _selectMulatschakPlayer(item);
          return;
        }
        if (isHosnObeMode) {
          _selectHosnObePlayer(item);
          return;
        }
        _selectCounter(item);
      },
      onRenameItem: isWattenMode
          ? (game) {
              _showRenameWattenGameDialog(game);
            }
          : isMulatschakMode
          ? (player) {
              _showRenameMulatschakPlayerDialog(player);
            }
          : isHosnObeMode
          ? (player) {
              _showRenameHosnObePlayerDialog(player);
            }
          : (counter) {
              _showRenameCounterDialog(counter);
            },
      onDeleteItem: (item) {
        if (isWattenMode) {
          _showDeleteWattenGameDialog(item);
          return;
        }
        if (isMulatschakMode) {
          _showDeleteMulatschakPlayerDialog(item);
          return;
        }
        if (isHosnObeMode) {
          _showDeleteHosnObePlayerDialog(item);
          return;
        }
        _showDeleteCounterDialog(item);
      },
      onReorderItems: isWattenMode
          ? _reorderWattenGames
          : isMulatschakMode
          ? _reorderMulatschakPlayers
          : isHosnObeMode
          ? _reorderHosnObePlayers
          : _reorderCounters,
      onOpenSettings: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => SettingsPage(
              currentThemeMode: widget.themeMode,
              onThemeModeChanged: widget.onThemeModeChanged,
              currentAppMode: widget.appMode,
              onAppModeChanged: _handleAppModeChanged,
              muleqackEnabled: muleqackEnabled,
              muleqackTriggerPoints: muleqackTriggerPoints,
              muleqackResetPoints: muleqackResetPoints,
              counterHistoryEnabled: counterHistoryEnabled,
              mulatschakHistoryEnabled: mulatschakHistoryEnabled,
              onMuleqackEnabledChanged: _setMuleqackEnabled,
              onMuleqackTriggerPointsChanged: _setMuleqackTriggerPoints,
              onMuleqackResetPointsChanged: _setMuleqackResetPoints,
              onCounterHistoryEnabledChanged: _setCounterHistoryEnabled,
              onMulatschakHistoryEnabledChanged:
                  _setMulatschakHistoryEnabled,
            ),
          ),
        );
      },
    );
  }

  Widget _buildHistoryDrawer() {
    final currentHistory = counterHistory[currentCounter] ?? const <String>[];

    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Counter history'),
              subtitle: Text(currentCounter),
            ),
            const Divider(),
            Expanded(
              child: currentHistory.isEmpty
                  ? const Center(child: Text('No counter changes yet.'))
                  : ListView.separated(
                      itemCount: currentHistory.length,
                      separatorBuilder: (context, index) => const Divider(),
                      itemBuilder: (context, index) {
                        return ListTile(title: Text(currentHistory[index]));
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMulatschakHistoryDrawer() {
    final entries = mulatschakHistory
        .map(_decodeMulatschakHistoryEntry)
        .whereType<_MulatschakHistoryEntry>()
        .toList();
    final rounds = SplayTreeMap<int, List<_MulatschakHistoryEntry>>(
      (left, right) => right.compareTo(left),
    );

    for (final entry in entries) {
      rounds.putIfAbsent(entry.round, () => []).add(entry);
    }

    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const ListTile(
              leading: Icon(Icons.history),
              title: Text('Mulatschak history'),
              subtitle: Text('Player changes by round'),
            ),
            const Divider(),
            Expanded(
              child: rounds.isEmpty
                  ? const Center(child: Text('No player changes yet.'))
                  : ListView.separated(
                      itemCount: rounds.length,
                      separatorBuilder: (context, index) => const Divider(),
                      itemBuilder: (context, index) {
                        final roundEntry = rounds.entries.elementAt(index);
                        final roundEntries = roundEntry.value.reversed.toList();

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                              child: Text(
                                'Round ${roundEntry.key}',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                            ),
                            ...roundEntries.map(
                              (entry) => ListTile(
                                dense: true,
                                title: Text(entry.playerName),
                                subtitle: Text(entry.time),
                                trailing: Text(
                                  '${_formatSignedPoints(entry.points)} points',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCounterBody() {
    if (_isLoadingCounters) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 24),
          Text(
            currentCounter,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 42, fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: Center(
              child: Text(
                '${counters[currentCounter]}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 96,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          CounterControls(
            onIncrement: _increment,
            onDecrement: _decrement,
            onReset: _reset,
          ),
          const SizedBox(height: 24),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildWattenSideCard({
    required String title,
    required int score,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDesktopCard =
        !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.windows ||
            defaultTargetPlatform == TargetPlatform.macOS);

    return Expanded(
      child: ScoreCard(
        title: title,
        score: score,
        isSelected: isSelected,
        onTap: onTap,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        constraints: BoxConstraints(
          minHeight: isDesktopCard ? 260 : 220,
          maxHeight: isDesktopCard ? 300 : 260,
        ),
      ),
    );
  }

  Widget _buildWattenBody() {
    if (_isLoadingCounters) {
      return const Center(child: CircularProgressIndicator());
    }

    final currentGame = wattenGames[currentWattenGame]!;
    final winner = _wattenWinner(currentGame);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (winner != null) WinnerBanner(winner: winner),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildWattenSideCard(
                  title: 'Me',
                  score: currentGame.me,
                  isSelected: selectedWattenSide == WattenSide.me,
                  onTap: () {
                    setState(() {
                      selectedWattenSide = WattenSide.me;
                    });
                  },
                ),
                _buildWattenSideCard(
                  title: 'You',
                  score: currentGame.you,
                  isSelected: selectedWattenSide == WattenSide.you,
                  onTap: () {
                    setState(() {
                      selectedWattenSide = WattenSide.you;
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildWattenControls(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildMulatschakPlayerCard(
    String playerName,
    int score, {
    bool compact = false,
  }) {
    final isSelected = playerName == currentMulatschakPlayer;

    return ScoreCard(
      title: playerName,
      score: score,
      isSelected: isSelected,
      compact: compact,
      onTap: () {
        FocusScope.of(context).unfocus();
        _selectMulatschakPlayer(playerName);
      },
    );
  }

  Widget _buildMulatschakMultiplierSelector() {
    const multipliers = [1, 2, 4, 8, 16, 32, 64, 128];
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: 76,
      child: PopupMenuButton<int>(
        key: const Key('mulatschakMultiplierButton'),
        tooltip: 'Multiplier',
        initialValue: multipliers.contains(mulatschakMultiplier)
            ? mulatschakMultiplier
            : null,
        constraints: const BoxConstraints.tightFor(width: 76),
        position: PopupMenuPosition.over,
        onSelected: _setMulatschakMultiplier,
        itemBuilder: (context) => multipliers
            .map(
              (multiplier) => PopupMenuItem<int>(
                value: multiplier,
                height: 44,
                child: Center(child: Text('${multiplier}x')),
              ),
            )
            .toList(),
        child: Container(
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).dividerColor),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '${mulatschakMultiplier}x',
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  bool _isHandsetWidth(double width) {
    final platform = defaultTargetPlatform;
    final isMobilePlatform =
        platform == TargetPlatform.android || platform == TargetPlatform.iOS;

    return isMobilePlatform && width < 600;
  }

  Widget _buildMulatschakMultiplierRow() {
    const label = Text(
      'Multiplier',
      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (_isHandsetWidth(constraints.maxWidth)) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              label,
              _buildMulatschakMultiplierSelector(),
            ],
          );
        }

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            label,
            const SizedBox(width: 16),
            _buildMulatschakMultiplierSelector(),
          ],
        );
      },
    );
  }

  Widget _buildMulatschakControls() {
    return Column(
      children: [
        _buildMulatschakMultiplierRow(),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScoreButton(
              label: '-1',
              onPressed: () => _updateMulatschakScore(-1),
            ),
            const SizedBox(width: 20),
            ScoreButton(
              label: '+1',
              onPressed: () => _updateMulatschakScore(1),
            ),
            const SizedBox(width: 20),
            ScoreButton(
              label: '+5',
              onPressed: () => _updateMulatschakScore(5),
              minimumSize: const Size(120, 80),
            ),
          ],
        ),
        const SizedBox(height: 20),
        ScoreButton(
          label: 'Reset',
          onPressed: _resetMulatschakPlayers,
          minimumSize: const Size(120, 80),
        ),
      ],
    );
  }

  bool _useHandsetMulatschakGrid(BoxConstraints constraints) {
    return _isHandsetWidth(constraints.maxWidth);
  }

  Widget _buildMulatschakPlayersWrap(
    List<MapEntry<String, int>> entries,
  ) {
    return SingleChildScrollView(
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 12,
        runSpacing: 12,
        children: entries
            .map(
              (entry) => SizedBox(
                width: 180,
                child: _buildMulatschakPlayerCard(entry.key, entry.value),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildMulatschakPlayersGrid(
    List<MapEntry<String, int>> entries,
  ) {
    final columnCount = entries.length >= 3 ? 3 : entries.length;

    return GridView.count(
      crossAxisCount: columnCount,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 0.68,
      children: entries
          .map(
            (entry) => _buildMulatschakPlayerCard(
              entry.key,
              entry.value,
              compact: true,
            ),
          )
          .toList(),
    );
  }

  Widget _buildMulatschakBody() {
    if (_isLoadingCounters) {
      return const Center(child: CircularProgressIndicator());
    }

    final winner = _mulatschakWinner();
    final entries = mulatschakPlayers.entries.toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      child: Column(
        children: [
          if (winner != null) WinnerBanner(winner: winner),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (_useHandsetMulatschakGrid(constraints) &&
                    entries.length >= 2) {
                  return _buildMulatschakPlayersGrid(entries);
                }

                return _buildMulatschakPlayersWrap(entries);
              },
            ),
          ),
          const SizedBox(height: 20),
          _buildMulatschakControls(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildHosnObePlayerCard(String playerName, int score) {
    final isSelected = playerName == currentHosnObePlayer;

    return ScoreCard(
      title: playerName,
      score: score,
      isSelected: isSelected,
      width: 180,
      onTap: () {
        _selectHosnObePlayer(playerName);
      },
    );
  }

  Widget _buildHosnObeControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ScoreButton(
          label: '-1',
          onPressed: () => _updateHosnObeScore(-1),
        ),
        const SizedBox(width: 20),
        ScoreButton(
          label: 'Reset',
          onPressed: _resetHosnObePlayers,
          minimumSize: const Size(120, 80),
        ),
      ],
    );
  }

  Widget _buildHosnObeBody() {
    if (_isLoadingCounters) {
      return const Center(child: CircularProgressIndicator());
    }

    final winner = _hosnObeWinner();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      child: Column(
        children: [
          if (winner != null) WinnerBanner(winner: winner),
          Expanded(
            child: SingleChildScrollView(
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 12,
                children: hosnObePlayers.entries
                    .map(
                      (entry) =>
                          _buildHosnObePlayerCard(entry.key, entry.value),
                    )
                    .toList(),
              ),
            ),
          ),
          const SizedBox(height: 20),
          _buildHosnObeControls(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobileDrawerGesture =
        !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);

    return Scaffold(
      key: _scaffoldKey,
      appBar: _buildAppBar(),
      drawer: _buildDrawer(),
      endDrawer: widget.appMode == AppMode.counter && counterHistoryEnabled
          ? _buildHistoryDrawer()
          : widget.appMode == AppMode.mulatschak && mulatschakHistoryEnabled
          ? _buildMulatschakHistoryDrawer()
          : null,
      drawerEdgeDragWidth: isMobileDrawerGesture ? screenWidth * 0.5 : null,
      body: widget.appMode == AppMode.watten
          ? _buildWattenBody()
          : widget.appMode == AppMode.mulatschak
          ? _buildMulatschakBody()
          : widget.appMode == AppMode.hosnObe
          ? _buildHosnObeBody()
          : _buildCounterBody(),
    );
  }
}
