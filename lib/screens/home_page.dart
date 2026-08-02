import 'package:flutter/material.dart';
import 'dart:collection';

import '../features/counter/counter_body.dart';
import '../features/hosn_obe/hosn_obe_body.dart';
import '../features/mulatschak/mulatschak_body.dart';
import '../features/watten/watten_body.dart';
import '../models/app_mode.dart';
import '../models/game_rules.dart';
import '../models/mulatschak_history_entry.dart';
import '../models/watten_game.dart';
import '../models/watten_side.dart';
import '../services/counter_storage_service.dart';
import '../utils/history_utils.dart';
import '../utils/name_utils.dart';
import '../utils/ordered_map_utils.dart';
import '../utils/responsive_utils.dart';
import '../widgets/app_dialogs.dart';
import '../widgets/counter_history_drawer.dart';
import '../widgets/counter_drawer.dart';
import '../widgets/mulatschak_history_drawer.dart';
import 'settings_page.dart';

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
  final bool counterNegativeEnabled;
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
    required this.counterNegativeEnabled,
    required this.counterHistory,
    required this.mulatschakHistoryEnabled,
    required this.mulatschakHistory,
    required this.mulatschakHistoryRound,
    required this.mulatschakRoundPlayers,
    required this.appMode,
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
  bool counterNegativeEnabled =
      CounterStorageService.defaultCounterNegativeEnabled;
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
      counterNegativeEnabled = storedData.counterNegativeEnabled;
      counterHistory = HistoryUtils.copyCounterHistory(
        storedData.counterHistory,
      );
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
      counterNegativeEnabled: counterNegativeEnabled,
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
      counterNegativeEnabled: counterNegativeEnabled,
      counterHistory: HistoryUtils.copyCounterHistory(counterHistory),
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
        counterNegativeEnabled = snapshot.counterNegativeEnabled;
        counterHistory = HistoryUtils.copyCounterHistory(
          snapshot.counterHistory,
        );
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
    if (!counterNegativeEnabled && counters[currentCounter]! <= 0) {
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
        '${HistoryUtils.formatTime(DateTime.now())} - $action.',
        ...currentHistory,
      ];
  }

  void _recordMulatschakHistory(String playerName, int points) {
    if (!mulatschakHistoryEnabled || points == 0) {
      return;
    }

    mulatschakHistory = [
      ...mulatschakHistory,
      MulatschakHistoryEntry(
        round: mulatschakHistoryRound,
        time: HistoryUtils.formatTime(DateTime.now()),
        playerName: playerName,
        points: points,
      ).encode(),
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
    return NameUtils.isUnique(counterName, counters.keys);
  }

  bool _isWattenGameNameValid(String gameName) {
    return NameUtils.isUnique(gameName, wattenGames.keys);
  }

  bool _isMulatschakPlayerNameValid(String playerName) {
    return NameUtils.isUnique(playerName, mulatschakPlayers.keys);
  }

  bool _isHosnObePlayerNameValid(String playerName) {
    return NameUtils.isUnique(playerName, hosnObePlayers.keys);
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
      counters = OrderedMapUtils.renameKey(counters, oldName, newName);
      counterHistory = OrderedMapUtils.renameKey(
        counterHistory,
        oldName,
        newName,
        copyValue: List<String>.from,
      );
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
      wattenGames = OrderedMapUtils.renameKey(wattenGames, oldName, newName);
      if (currentWattenGame == oldName) {
        currentWattenGame = newName;
      }
    });
    _saveCounters();
  }

  void _renameMulatschakPlayer(String oldName, String newName) {
    _pushUndoSnapshot();
    setState(() {
      mulatschakPlayers = OrderedMapUtils.renameKey(
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
      hosnObePlayers = OrderedMapUtils.renameKey(
        hosnObePlayers,
        oldName,
        newName,
      );
      if (currentHosnObePlayer == oldName) {
        currentHosnObePlayer = newName;
      }
    });
    _saveCounters();
  }

  void _reorderCounters(int oldIndex, int newIndex) {
    final reordered = OrderedMapUtils.reorder(counters, oldIndex, newIndex);
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
    final reordered = OrderedMapUtils.reorder(
      mulatschakPlayers,
      oldIndex,
      newIndex,
    );
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
    final reordered = OrderedMapUtils.reorder(
      hosnObePlayers,
      oldIndex,
      newIndex,
    );
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
    final reordered = OrderedMapUtils.reorder(wattenGames, oldIndex, newIndex);
    if (reordered == null) {
      return;
    }

    _pushUndoSnapshot();
    setState(() {
      wattenGames = reordered;
    });
    _saveCounters();
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

  void _setCounterNegativeEnabled(bool enabled) {
    if (counterNegativeEnabled == enabled) {
      return;
    }

    _pushUndoSnapshot();
    setState(() {
      counterNegativeEnabled = enabled;
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
    AppDialogs.showAddItemDialog(
      context: context,
      title: 'Add Counter',
      hintText: 'Counter name',
      isValidName: _isCounterNameValid,
      onAdd: _addCounterToList,
    );
  }

  void _showAddWattenGameDialog() {
    AppDialogs.showAddItemDialog(
      context: context,
      title: 'Add Game',
      hintText: 'Game name',
      isValidName: _isWattenGameNameValid,
      onAdd: _addWattenGame,
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
    AppDialogs.showAddItemDialog(
      context: context,
      title: 'Add Player',
      hintText: 'Player name',
      isValidName: isValidName,
      onAdd: onAdd,
    );
  }

  void _showRenameCounterDialog(String oldName) {
    AppDialogs.showRenameItemDialog(
      context: context,
      title: 'Rename Counter',
      initialValue: oldName,
      hintText: 'New counter name',
      duplicateNameMessage: 'This counter name can only be used once.',
      isValidName: (newName) {
        return NameUtils.isUniqueExcept(newName, counters.keys, oldName);
      },
      onRename: (newName) {
        if (newName != oldName) {
          _renameCounter(oldName, newName);
        }
      },
    );
  }

  void _showRenameWattenGameDialog(String oldName) {
    AppDialogs.showRenameItemDialog(
      context: context,
      title: 'Rename Game',
      initialValue: oldName,
      hintText: 'New game name',
      duplicateNameMessage: 'This game name can only be used once.',
      isValidName: (newName) {
        return NameUtils.isUniqueExcept(newName, wattenGames.keys, oldName);
      },
      onRename: (newName) {
        if (newName != oldName) {
          _renameWattenGame(oldName, newName);
        }
      },
    );
  }

  void _showRenameMulatschakPlayerDialog(String oldName) {
    AppDialogs.showRenameItemDialog(
      context: context,
      title: 'Rename Player',
      initialValue: oldName,
      hintText: 'New player name',
      duplicateNameMessage: 'This player name can only be used once.',
      isValidName: (newName) {
        return NameUtils.isUniqueExcept(
          newName,
          mulatschakPlayers.keys,
          oldName,
        );
      },
      onRename: (newName) {
        if (newName != oldName) {
          _renameMulatschakPlayer(oldName, newName);
        }
      },
    );
  }

  void _showRenameHosnObePlayerDialog(String oldName) {
    AppDialogs.showRenameItemDialog(
      context: context,
      title: 'Rename Player',
      initialValue: oldName,
      hintText: 'New player name',
      duplicateNameMessage: 'This player name can only be used once.',
      isValidName: (newName) {
        return NameUtils.isUniqueExcept(newName, hosnObePlayers.keys, oldName);
      },
      onRename: (newName) {
        if (newName != oldName) {
          _renameHosnObePlayer(oldName, newName);
        }
      },
    );
  }

  void _showDeleteCounterDialog(String counterName) {
    AppDialogs.showDeleteItemDialog(
      context: context,
      title: 'Delete Counter',
      itemName: counterName,
      autofocusDelete: true,
      onDelete: _deleteCounter,
    );
  }

  void _showDeleteWattenGameDialog(String gameName) {
    AppDialogs.showDeleteItemDialog(
      context: context,
      title: 'Delete Game',
      itemName: gameName,
      onDelete: _deleteWattenGame,
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
    AppDialogs.showDeleteItemDialog(
      context: context,
      title: 'Delete Player',
      itemName: playerName,
      autofocusDelete: true,
      onDelete: onDelete,
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
              counterNegativeEnabled: counterNegativeEnabled,
              mulatschakHistoryEnabled: mulatschakHistoryEnabled,
              onMuleqackEnabledChanged: _setMuleqackEnabled,
              onMuleqackTriggerPointsChanged: _setMuleqackTriggerPoints,
              onMuleqackResetPointsChanged: _setMuleqackResetPoints,
              onCounterHistoryEnabledChanged: _setCounterHistoryEnabled,
              onCounterNegativeEnabledChanged: _setCounterNegativeEnabled,
              onMulatschakHistoryEnabledChanged: _setMulatschakHistoryEnabled,
            ),
          ),
        );
      },
    );
  }

  Widget _buildEndDrawer() {
    if (widget.appMode == AppMode.counter && counterHistoryEnabled) {
      return CounterHistoryDrawer(
        currentCounter: currentCounter,
        currentHistory: counterHistory[currentCounter] ?? const <String>[],
      );
    }

    if (widget.appMode == AppMode.mulatschak && mulatschakHistoryEnabled) {
      return MulatschakHistoryDrawer(history: mulatschakHistory);
    }

    return const SizedBox.shrink();
  }

  Widget _buildBody() {
    switch (widget.appMode) {
      case AppMode.counter:
        return CounterBody(
          isLoading: _isLoadingCounters,
          counterName: currentCounter,
          score: counters[currentCounter] ?? 0,
          onIncrement: _increment,
          onDecrement: _decrement,
          onReset: _reset,
        );
      case AppMode.watten:
        final currentGame =
            wattenGames[currentWattenGame] ?? const WattenGame(me: 0, you: 0);

        return WattenBody(
          isLoading: _isLoadingCounters,
          currentGame: currentGame,
          selectedSide: selectedWattenSide,
          winner: _wattenWinner(currentGame),
          onSelectedSideChanged: (side) {
            setState(() {
              selectedWattenSide = side;
            });
          },
          onScoreChanged: _updateWattenScore,
          onResetSelectedSide: _resetWattenSelectedSide,
        );
      case AppMode.mulatschak:
        return MulatschakBody(
          isLoading: _isLoadingCounters,
          players: mulatschakPlayers,
          currentPlayer: currentMulatschakPlayer,
          multiplier: mulatschakMultiplier,
          winner: _mulatschakWinner(),
          onPlayerSelected: _selectMulatschakPlayer,
          onScoreChanged: _updateMulatschakScore,
          onMultiplierChanged: _setMulatschakMultiplier,
          onResetPlayers: _resetMulatschakPlayers,
        );
      case AppMode.hosnObe:
        return HosnObeBody(
          isLoading: _isLoadingCounters,
          players: hosnObePlayers,
          currentPlayer: currentHosnObePlayer,
          winner: _hosnObeWinner(),
          onPlayerSelected: _selectHosnObePlayer,
          onScoreChanged: _updateHosnObeScore,
          onResetPlayers: _resetHosnObePlayers,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobileDrawerGesture = ResponsiveUtils.isMobilePlatform;
    final body = _buildBody();

    return Scaffold(
      key: _scaffoldKey,
      appBar: _buildAppBar(),
      drawer: _buildDrawer(),
      endDrawer:
          widget.appMode == AppMode.counter && counterHistoryEnabled ||
              widget.appMode == AppMode.mulatschak && mulatschakHistoryEnabled
          ? _buildEndDrawer()
          : null,
      drawerEdgeDragWidth: isMobileDrawerGesture ? screenWidth * 0.5 : null,
      body: SafeArea(top: false, child: body),
    );
  }
}
