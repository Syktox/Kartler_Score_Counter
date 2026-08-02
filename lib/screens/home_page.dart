import 'dart:collection';

import 'package:flutter/material.dart';

import '../features/counter/counter_body.dart';
import '../features/counter/counter_helper.dart';
import '../features/hosn_obe/hosn_obe_body.dart';
import '../features/hosn_obe/hosn_obe_helper.dart';
import '../features/mulatschak/mulatschak_body.dart';
import '../features/mulatschak/mulatschak_helper.dart';
import '../features/watten/watten_body.dart';
import '../features/watten/watten_helper.dart';
import '../models/app_mode.dart';
import '../models/game_rules.dart';
import '../models/watten_game.dart';
import '../models/watten_side.dart';
import '../services/counter_storage_service.dart';
import '../utils/history_utils.dart';
import '../utils/name_utils.dart';
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

class _DrawerConfig {
  final List<String> items;
  final String selectedItem;
  final String addButtonLabel;
  final IconData addButtonIcon;
  final bool closeDrawerOnAdd;
  final VoidCallback onAddNewItem;
  final ValueChanged<String> onSelectItem;
  final ValueChanged<String> onRenameItem;
  final ValueChanged<String> onDeleteItem;
  final ReorderItemsCallback onReorderItems;

  const _DrawerConfig({
    required this.items,
    required this.selectedItem,
    required this.addButtonLabel,
    required this.addButtonIcon,
    required this.closeDrawerOnAdd,
    required this.onAddNewItem,
    required this.onSelectItem,
    required this.onRenameItem,
    required this.onDeleteItem,
    required this.onReorderItems,
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

  void _updateAndSave(VoidCallback update) {
    setState(update);
    _saveCounters();
  }

  void _updateWithUndoAndSave(VoidCallback update) {
    _pushUndoSnapshot();
    setState(update);
    _saveCounters();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _increment() {
    _updateWithUndoAndSave(() {
      final result = CounterHelper.updateScore(
        counters: counters,
        history: counterHistory,
        currentCounter: currentCounter,
        historyEnabled: counterHistoryEnabled,
        score: counters[currentCounter]! + 1,
        action: 'increased',
      );
      counters = result.counters;
      counterHistory = result.history;
    });
  }

  void _decrement() {
    if (!CounterHelper.canDecrement(
      score: counters[currentCounter]!,
      allowNegative: counterNegativeEnabled,
    )) {
      return;
    }

    _updateWithUndoAndSave(() {
      final result = CounterHelper.updateScore(
        counters: counters,
        history: counterHistory,
        currentCounter: currentCounter,
        historyEnabled: counterHistoryEnabled,
        score: counters[currentCounter]! - 1,
        action: 'decreased',
      );
      counters = result.counters;
      counterHistory = result.history;
    });
  }

  void _reset() {
    if (counters[currentCounter] == 0) {
      return;
    }

    _updateWithUndoAndSave(() {
      final result = CounterHelper.updateScore(
        counters: counters,
        history: counterHistory,
        currentCounter: currentCounter,
        historyEnabled: counterHistoryEnabled,
        score: 0,
        action: 'reseted',
      );
      counters = result.counters;
      counterHistory = result.history;
    });
  }

  void _recordMulatschakHistory(String playerName, int points) {
    final result = MulatschakHelper.recordHistory(
      enabled: mulatschakHistoryEnabled,
      history: mulatschakHistory,
      players: mulatschakPlayers,
      roundPlayers: mulatschakRoundPlayers,
      historyRound: mulatschakHistoryRound,
      playerName: playerName,
      points: points,
    );
    mulatschakHistory = result.history;
    mulatschakRoundPlayers = result.roundPlayers;
    mulatschakHistoryRound = result.historyRound;
  }

  void _selectCounter(String counter) {
    if (currentCounter == counter) {
      return;
    }

    _updateAndSave(() {
      currentCounter = counter;
    });
  }

  bool _isCounterNameValid(String counterName) {
    return CounterHelper.isNameValid(counterName, counters.keys);
  }

  bool _isWattenGameNameValid(String gameName) {
    return WattenHelper.isGameNameValid(gameName, wattenGames.keys);
  }

  bool _isMulatschakPlayerNameValid(String playerName) {
    return MulatschakHelper.isPlayerNameValid(
      playerName,
      mulatschakPlayers.keys,
    );
  }

  bool _isHosnObePlayerNameValid(String playerName) {
    return HosnObeHelper.isPlayerNameValid(playerName, hosnObePlayers.keys);
  }

  String? _wattenWinner(WattenGame game) {
    return WattenHelper.winner(game);
  }

  String? _mulatschakWinner() {
    return MulatschakHelper.winner(mulatschakPlayers);
  }

  String? _hosnObeWinner() {
    return HosnObeHelper.winner(hosnObePlayers);
  }

  void _addCounterToList(String counterName) {
    _updateWithUndoAndSave(() {
      final result = CounterHelper.addCounter(
        counters: counters,
        counterName: counterName,
      );
      counters = result.counters;
      currentCounter = result.currentCounter;
    });
  }

  void _renameCounter(String oldName, String newName) {
    _updateWithUndoAndSave(() {
      final result = CounterHelper.renameCounter(
        counters: counters,
        history: counterHistory,
        currentCounter: currentCounter,
        oldName: oldName,
        newName: newName,
      );
      counters = result.counters;
      counterHistory = result.history;
      currentCounter = result.currentCounter;
    });
  }

  void _deleteCounter(String counterName) {
    if (counters.length <= 1) {
      _showMessage('At least one counter must remain.');
      return;
    }

    _updateWithUndoAndSave(() {
      final result = CounterHelper.deleteCounter(
        counters: counters,
        history: counterHistory,
        currentCounter: currentCounter,
        counterName: counterName,
      );
      counters = result.counters;
      counterHistory = result.history;
      currentCounter = result.currentCounter;
    });
  }

  void _selectWattenGame(String gameName) {
    if (currentWattenGame == gameName) {
      return;
    }

    _updateAndSave(() {
      currentWattenGame = gameName;
    });
  }

  void _renameWattenGame(String oldName, String newName) {
    _updateWithUndoAndSave(() {
      wattenGames = WattenHelper.renameGame(
        games: wattenGames,
        oldName: oldName,
        newName: newName,
      );
      if (currentWattenGame == oldName) {
        currentWattenGame = newName;
      }
    });
  }

  void _renameMulatschakPlayer(String oldName, String newName) {
    _updateWithUndoAndSave(() {
      final result = MulatschakHelper.renamePlayer(
        players: mulatschakPlayers,
        currentPlayer: currentMulatschakPlayer,
        roundPlayers: mulatschakRoundPlayers,
        oldName: oldName,
        newName: newName,
      );
      mulatschakPlayers = result.players;
      currentMulatschakPlayer = result.currentPlayer;
      mulatschakRoundPlayers = result.roundPlayers;
    });
  }

  void _renameHosnObePlayer(String oldName, String newName) {
    _updateWithUndoAndSave(() {
      final result = HosnObeHelper.renamePlayer(
        players: hosnObePlayers,
        currentPlayer: currentHosnObePlayer,
        oldName: oldName,
        newName: newName,
      );
      hosnObePlayers = result.players;
      currentHosnObePlayer = result.currentPlayer;
    });
  }

  void _reorderCounters(int oldIndex, int newIndex) {
    final reordered = CounterHelper.reorderCounters(
      counters,
      oldIndex,
      newIndex,
    );
    if (reordered == null) {
      return;
    }

    _updateWithUndoAndSave(() {
      counters = reordered;
    });
  }

  void _reorderMulatschakPlayers(int oldIndex, int newIndex) {
    final reordered = MulatschakHelper.reorderPlayers(
      mulatschakPlayers,
      oldIndex,
      newIndex,
    );
    if (reordered == null) {
      return;
    }

    _updateWithUndoAndSave(() {
      mulatschakPlayers = reordered;
    });
  }

  void _reorderHosnObePlayers(int oldIndex, int newIndex) {
    final reordered = HosnObeHelper.reorderPlayers(
      hosnObePlayers,
      oldIndex,
      newIndex,
    );
    if (reordered == null) {
      return;
    }

    _updateWithUndoAndSave(() {
      hosnObePlayers = reordered;
    });
  }

  void _reorderWattenGames(int oldIndex, int newIndex) {
    final reordered = WattenHelper.reorderGames(
      wattenGames,
      oldIndex,
      newIndex,
    );
    if (reordered == null) {
      return;
    }

    _updateWithUndoAndSave(() {
      wattenGames = reordered;
    });
  }

  void _addWattenGame(String gameName) {
    _updateWithUndoAndSave(() {
      final result = WattenHelper.addGame(
        games: wattenGames,
        gameName: gameName,
      );
      wattenGames = result.games;
      currentWattenGame = result.currentGame;
      selectedWattenSide = result.selectedSide;
    });
  }

  void _deleteWattenGame(String gameName) {
    if (wattenGames.length <= 1) {
      _showMessage('At least one game must remain.');
      return;
    }

    _updateWithUndoAndSave(() {
      final result = WattenHelper.deleteGame(
        games: wattenGames,
        currentGame: currentWattenGame,
        gameName: gameName,
      );
      wattenGames = result.games;
      currentWattenGame = result.currentGame;
    });
  }

  void _selectMulatschakPlayer(String playerName) {
    if (currentMulatschakPlayer == playerName) {
      return;
    }

    _updateAndSave(() {
      currentMulatschakPlayer = playerName;
    });
  }

  void _selectHosnObePlayer(String playerName) {
    if (currentHosnObePlayer == playerName) {
      return;
    }

    _updateAndSave(() {
      currentHosnObePlayer = playerName;
    });
  }

  void _addMulatschakPlayer(String playerName) {
    _updateWithUndoAndSave(() {
      final result = MulatschakHelper.addPlayer(
        players: mulatschakPlayers,
        roundPlayers: mulatschakRoundPlayers,
        playerName: playerName,
      );
      mulatschakPlayers = result.players;
      currentMulatschakPlayer = result.currentPlayer;
      mulatschakRoundPlayers = result.roundPlayers;
    });
  }

  void _addHosnObePlayer(String playerName) {
    _updateWithUndoAndSave(() {
      final result = HosnObeHelper.addPlayer(
        players: hosnObePlayers,
        playerName: playerName,
      );
      hosnObePlayers = result.players;
      currentHosnObePlayer = result.currentPlayer;
    });
  }

  void _deleteMulatschakPlayer(String playerName) {
    if (mulatschakPlayers.length <= 1) {
      _showMessage('At least one player must remain.');
      return;
    }

    _updateWithUndoAndSave(() {
      final result = MulatschakHelper.deletePlayer(
        players: mulatschakPlayers,
        currentPlayer: currentMulatschakPlayer,
        roundPlayers: mulatschakRoundPlayers,
        historyRound: mulatschakHistoryRound,
        playerName: playerName,
      );
      mulatschakPlayers = result.players;
      currentMulatschakPlayer = result.currentPlayer;
      mulatschakRoundPlayers = result.roundPlayers;
      mulatschakHistoryRound = result.historyRound;
    });
  }

  void _deleteHosnObePlayer(String playerName) {
    if (hosnObePlayers.length <= 1) {
      _showMessage('At least one player must remain.');
      return;
    }

    _updateWithUndoAndSave(() {
      final result = HosnObeHelper.deletePlayer(
        players: hosnObePlayers,
        currentPlayer: currentHosnObePlayer,
        playerName: playerName,
      );
      hosnObePlayers = result.players;
      currentHosnObePlayer = result.currentPlayer;
    });
  }

  void _updateHosnObeScore(int delta) {
    final currentValue = hosnObePlayers[currentHosnObePlayer]!;
    final nextValue = currentValue + delta;

    if (nextValue < 0) {
      return;
    }

    _updateWithUndoAndSave(() {
      hosnObePlayers = HosnObeHelper.updateScore(
        players: hosnObePlayers,
        currentPlayer: currentHosnObePlayer,
        score: nextValue,
      );
    });
  }

  void _resetHosnObePlayers() {
    if (hosnObePlayers.values.every(
      (value) => value == GameRules.hosnObeStartingLives,
    )) {
      return;
    }

    _updateWithUndoAndSave(() {
      hosnObePlayers = HosnObeHelper.resetPlayers(hosnObePlayers);
    });
  }

  void _updateMulatschakScore(int baseDelta) {
    final playerName = currentMulatschakPlayer;
    final currentValue = mulatschakPlayers[playerName]!;
    final nextValue = MulatschakHelper.nextScore(
      currentValue: currentValue,
      baseDelta: baseDelta,
      multiplier: mulatschakMultiplier,
      muleqackEnabled: muleqackEnabled,
      triggerPoints: muleqackTriggerPoints,
      resetPoints: muleqackResetPoints,
    );

    _updateWithUndoAndSave(() {
      mulatschakPlayers[playerName] = nextValue;
      _recordMulatschakHistory(playerName, nextValue - currentValue);
    });
  }

  void _resetMulatschakPlayers() {
    if (mulatschakPlayers.values.every(
      (value) => value == GameRules.mulatschakStartingScore,
    )) {
      return;
    }

    _updateWithUndoAndSave(() {
      mulatschakPlayers.updateAll((playerName, value) {
        const resetValue = GameRules.mulatschakStartingScore;
        _recordMulatschakHistory(playerName, resetValue - value);
        return resetValue;
      });
    });
  }

  void _setMulatschakMultiplier(int multiplier) {
    if (mulatschakMultiplier == multiplier) {
      return;
    }

    _updateWithUndoAndSave(() {
      mulatschakMultiplier = multiplier;
    });
  }

  void _setMuleqackEnabled(bool enabled) {
    if (muleqackEnabled == enabled) {
      return;
    }

    _updateWithUndoAndSave(() {
      muleqackEnabled = enabled;
    });
  }

  void _setMuleqackTriggerPoints(int points) {
    if (muleqackTriggerPoints == points) {
      return;
    }

    _updateWithUndoAndSave(() {
      muleqackTriggerPoints = points;
    });
  }

  void _setMuleqackResetPoints(int points) {
    if (muleqackResetPoints == points) {
      return;
    }

    _updateWithUndoAndSave(() {
      muleqackResetPoints = points;
    });
  }

  void _setCounterHistoryEnabled(bool enabled) {
    if (counterHistoryEnabled == enabled) {
      return;
    }

    _updateWithUndoAndSave(() {
      counterHistoryEnabled = enabled;
    });
  }

  void _setCounterNegativeEnabled(bool enabled) {
    if (counterNegativeEnabled == enabled) {
      return;
    }

    _updateWithUndoAndSave(() {
      counterNegativeEnabled = enabled;
    });
  }

  void _setMulatschakHistoryEnabled(bool enabled) {
    if (mulatschakHistoryEnabled == enabled) {
      return;
    }

    _updateWithUndoAndSave(() {
      mulatschakHistoryEnabled = enabled;
    });
  }

  void _updateWattenScore(int delta) {
    final currentGame = wattenGames[currentWattenGame]!;
    final currentValue = WattenHelper.sideScore(
      currentGame,
      selectedWattenSide,
    );
    final nextValue = currentValue + delta;

    if (nextValue < 0) {
      return;
    }

    _updateWithUndoAndSave(() {
      wattenGames[currentWattenGame] = WattenHelper.updateSideScore(
        game: currentGame,
        side: selectedWattenSide,
        delta: delta,
      );
    });
  }

  void _resetWattenSelectedSide() {
    final currentGame = wattenGames[currentWattenGame]!;
    final currentValue = WattenHelper.sideScore(
      currentGame,
      selectedWattenSide,
    );

    if (currentValue == 0) {
      return;
    }

    _updateWithUndoAndSave(() {
      wattenGames[currentWattenGame] = WattenHelper.resetSideScore(
        game: currentGame,
        side: selectedWattenSide,
      );
    });
  }

  void _selectWattenSide(WattenSide side) {
    if (selectedWattenSide == side) {
      return;
    }

    setState(() {
      selectedWattenSide = side;
    });
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

  _DrawerConfig _drawerConfig() {
    switch (widget.appMode) {
      case AppMode.counter:
        return _DrawerConfig(
          items: counters.keys.toList(),
          selectedItem: currentCounter,
          addButtonLabel: 'New Counter',
          addButtonIcon: Icons.add,
          closeDrawerOnAdd: true,
          onAddNewItem: _showAddCounterDialog,
          onSelectItem: _selectCounter,
          onRenameItem: _showRenameCounterDialog,
          onDeleteItem: _showDeleteCounterDialog,
          onReorderItems: _reorderCounters,
        );
      case AppMode.watten:
        return _DrawerConfig(
          items: wattenGames.keys.toList(),
          selectedItem: currentWattenGame,
          addButtonLabel: 'Add Game',
          addButtonIcon: Icons.add,
          closeDrawerOnAdd: true,
          onAddNewItem: _showAddWattenGameDialog,
          onSelectItem: _selectWattenGame,
          onRenameItem: _showRenameWattenGameDialog,
          onDeleteItem: _showDeleteWattenGameDialog,
          onReorderItems: _reorderWattenGames,
        );
      case AppMode.mulatschak:
        return _DrawerConfig(
          items: mulatschakPlayers.keys.toList(),
          selectedItem: currentMulatschakPlayer,
          addButtonLabel: 'Add Player',
          addButtonIcon: Icons.person_add_alt_1,
          closeDrawerOnAdd: false,
          onAddNewItem: _showAddMulatschakPlayerDialog,
          onSelectItem: _selectMulatschakPlayer,
          onRenameItem: _showRenameMulatschakPlayerDialog,
          onDeleteItem: _showDeleteMulatschakPlayerDialog,
          onReorderItems: _reorderMulatschakPlayers,
        );
      case AppMode.hosnObe:
        return _DrawerConfig(
          items: hosnObePlayers.keys.toList(),
          selectedItem: currentHosnObePlayer,
          addButtonLabel: 'Add Player',
          addButtonIcon: Icons.person_add_alt_1,
          closeDrawerOnAdd: false,
          onAddNewItem: _showAddHosnObePlayerDialog,
          onSelectItem: _selectHosnObePlayer,
          onRenameItem: _showRenameHosnObePlayerDialog,
          onDeleteItem: _showDeleteHosnObePlayerDialog,
          onReorderItems: _reorderHosnObePlayers,
        );
    }
  }

  Widget _buildDrawer() {
    final config = _drawerConfig();

    return CounterDrawer(
      items: config.items,
      selectedItem: config.selectedItem,
      addButtonLabel: config.addButtonLabel,
      addButtonIcon: config.addButtonIcon,
      closeDrawerOnAdd: config.closeDrawerOnAdd,
      enableReorder: true,
      onAddNewItem: config.onAddNewItem,
      onSelectItem: config.onSelectItem,
      onRenameItem: config.onRenameItem,
      onDeleteItem: config.onDeleteItem,
      onReorderItems: config.onReorderItems,
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

  bool get _hasEndDrawer {
    return widget.appMode == AppMode.counter && counterHistoryEnabled ||
        widget.appMode == AppMode.mulatschak && mulatschakHistoryEnabled;
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
          onSelectedSideChanged: _selectWattenSide,
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
      endDrawer: _hasEndDrawer ? _buildEndDrawer() : null,
      drawerEdgeDragWidth: isMobileDrawerGesture ? screenWidth * 0.5 : null,
      body: SafeArea(top: false, child: body),
    );
  }
}
