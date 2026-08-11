import 'dart:async';

import 'package:flutter/material.dart';

import '../../commands/command_history.dart';
import '../../core/haptics_service.dart';
import '../../features/counter/counter_body.dart';
import '../../features/counter/counter_controller.dart';
import '../../features/counter/counter_helper.dart';
import '../../features/game_session/finish_match_sheet.dart';
import '../../features/game_session/session_controller.dart';
import '../../features/game_session/session_summary_page.dart';
import '../../features/game_session/sessions_list_page.dart';
import '../../features/hosn_obe/hosn_obe_body.dart';
import '../../features/hosn_obe/hosn_obe_controller.dart';
import '../../features/mulatschak/mulatschak_body.dart';
import '../../features/mulatschak/mulatschak_controller.dart';
import '../../features/players/player_management_page.dart';
import '../../features/players/players_controller.dart';
import '../../features/settings/settings_controller.dart';
import '../../features/settings/settings_page.dart';
import '../../features/statistics/statistics_calculator.dart';
import '../../features/statistics/statistics_page.dart';
import '../../features/watten/watten_body.dart';
import '../../features/watten/watten_controller.dart';
import '../../features/watten/watten_helper.dart';
import '../feature_controller.dart';
import '../../models/app_mode.dart';
import '../../models/watten_game.dart';
import '../../models/watten_side.dart';
import '../../utils/name_utils.dart';
import '../../persistence/repositories/counter_repository.dart';
import '../../persistence/repositories/hosn_obe_repository.dart';
import '../../persistence/repositories/match_history_repository.dart';
import '../../persistence/repositories/mulatschak_repository.dart';
import '../../persistence/repositories/player_repository.dart';
import '../../persistence/repositories/session_repository.dart';
import '../../persistence/repositories/settings_repository.dart';
import '../../persistence/repositories/watten_repository.dart';
import '../../utils/responsive_utils.dart';
import '../../widgets/app_dialogs.dart';
import '../../widgets/counter_drawer.dart';
import '../../widgets/counter_history_drawer.dart';
import '../../widgets/mulatschak_history_drawer.dart';
import 'hub_page.dart';
import 'onboarding_page.dart';

/// Zentrale Shell der App.
///
/// Erstellt und lädt alle Feature-Controller, verdrahtet die Spielmodi und
/// koordiniert Navigation (Hub, Onboarding, Verwaltung), Undo/Redo sowie
/// das Aufzeichnen abgeschlossener Partien.
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
  late final SettingsController _settings;
  late final PlayersController _players;
  late final CounterController _counter;
  late final WattenController _watten;
  late final MulatschakController _mulatschak;
  late final HosnObeController _hosnObe;
  late final SessionController _sessions;
  late final HapticsService _haptics;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _settings = SettingsController(repository: const SettingsRepository());
    _haptics = HapticsService(isEnabled: () => _settings.hapticsEnabled);
    _players = PlayersController(
      repository: const PlayerRepository(),
      haptics: _haptics,
    );
    _counter = CounterController(
      repository: const CounterRepository(),
      settings: _settings,
      haptics: _haptics,
    );
    _watten = WattenController(
      repository: const WattenRepository(),
      settings: _settings,
      haptics: _haptics,
    );
    _mulatschak = MulatschakController(
      repository: const MulatschakRepository(),
      settings: _settings,
      players: _players,
      haptics: _haptics,
    );
    _hosnObe = HosnObeController(
      repository: const HosnObeRepository(),
      settings: _settings,
      players: _players,
      haptics: _haptics,
    );
    _sessions = SessionController(
      sessionRepository: const SessionRepository(),
      matchRepository: const MatchHistoryRepository(),
      haptics: _haptics,
    );

    _settings.addListener(_syncSettingsToApp);
    _syncSettingsToApp();
    _loadAll();
  }

  @override
  void dispose() {
    _settings.removeListener(_syncSettingsToApp);
    _settings.dispose();
    _players.dispose();
    _counter.dispose();
    _watten.dispose();
    _mulatschak.dispose();
    _hosnObe.dispose();
    _sessions.dispose();
    super.dispose();
  }

  /// Meldet Theme- und Modus-Änderungen an die App-Wurzel weiter.
  void _syncSettingsToApp() {
    if (_settings.themeMode != widget.themeMode) {
      widget.onThemeModeChanged(_settings.themeMode);
    }
    if (_settings.appMode != widget.appMode) {
      widget.onAppModeChanged(_settings.appMode);
    }
  }

  Future<void> _loadAll() async {
    await Future.wait([
      _settings.load(),
      _players.load(),
      _counter.load(),
      _watten.load(),
      _mulatschak.load(),
      _hosnObe.load(),
      _sessions.load(),
    ]);
    _syncSettingsToApp();
    if (mounted) {
      setState(() {
        _ready = true;
      });
    }
  }

  FeatureController forMode(AppMode mode) {
    switch (mode) {
      case AppMode.counter:
        return _counter;
      case AppMode.watten:
        return _watten;
      case AppMode.mulatschak:
        return _mulatschak;
      case AppMode.hosnObe:
        return _hosnObe;
    }
  }

  CommandHistory historyFor(AppMode mode) {
    switch (mode) {
      case AppMode.counter:
        return _counter.history;
      case AppMode.watten:
        return _watten.history;
      case AppMode.mulatschak:
        return _mulatschak.history;
      case AppMode.hosnObe:
        return _hosnObe.history;
    }
  }

  void _selectMode(AppMode mode) {
    if (mode == widget.appMode) {
      return;
    }
    _settings.setAppMode(mode);
  }

  Future<void> _openSettings() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SettingsPage(settings: _settings),
      ),
    );
  }

  Future<void> _openPlayers() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PlayerManagementPage(
          players: _players,
          mulatschak: _mulatschak,
          hosnObe: _hosnObe,
        ),
      ),
    );
  }

  Future<void> _openStatistics() async {
    final result = StatisticsCalculator.calculate(
      matches: _sessions.matches,
      sessions: _sessions.sessions,
    );
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StatisticsPage(
          result: result,
          players: _players,
          sessions: _sessions.sessions,
        ),
      ),
    );
  }

  Future<void> _openPastSessions() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SessionsListPage(
          sessions: _sessions.pastSessions,
          players: _players,
        ),
      ),
    );
  }

  void _startSession() {
    final active = _sessions.activeSession;
    if (active != null) {
      _showMessage('Es läuft bereits ein Spielabend.');
      return;
    }
    final playerIds = _players.players.map((player) => player.id).toList();
    unawaited(_sessions.startSession(playerIds));
    _showMessage('Spielabend gestartet – viel Spaß!');
  }

  Future<void> _endSession() async {
    final active = _sessions.activeSession;
    if (active == null) {
      _showMessage('Es läuft kein Spielabend.');
      return;
    }
    final ended = await _sessions.endSession();
    if (ended == null || !mounted) {
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SessionSummaryPage(
          session: ended,
          matches: _sessions.matchesForSession(ended.id),
          players: _players,
        ),
      ),
    );
  }

  Future<void> _showFinishMatchSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => FinishMatchSheet(
        initialMode: widget.appMode,
        previewFor: _previewFor,
        onRecord: (mode, {required resetBoard}) {
          _recordMatch(mode, resetBoard: resetBoard);
        },
      ),
    );
  }

  MatchPreview _previewFor(AppMode mode) {
    switch (mode) {
      case AppMode.counter:
        return MatchPreview(
          winnerId: null,
          winnerLabel: null,
          standings: [
            for (final entry in _counter.counters.entries)
              (name: entry.key, score: entry.value),
          ],
        );
      case AppMode.watten:
        final game = _watten.games[_watten.currentGame] ??
            const WattenGame(me: 0, you: 0);
        return MatchPreview(
          winnerId: null,
          winnerLabel: _watten.winner(),
          standings: [
            (name: WattenSide.me.label, score: game.me),
            (name: WattenSide.you.label, score: game.you),
          ],
        );
      case AppMode.mulatschak:
        return MatchPreview(
          winnerId: _mulatschak.winner(),
          winnerLabel: null,
          standings: [
            for (final entry in _mulatschak.lineup.entries)
              (name: _players.displayName(entry.key), score: entry.value),
          ],
        );
      case AppMode.hosnObe:
        return MatchPreview(
          winnerId: _hosnObe.winner(),
          winnerLabel: null,
          standings: [
            for (final entry in _hosnObe.lineup.entries)
              (name: _players.displayName(entry.key), score: entry.value),
          ],
        );
    }
  }

  void _recordMatch(AppMode mode, {required bool resetBoard}) {
    final preview = _previewFor(mode);

    final participantIds = switch (mode) {
      AppMode.mulatschak => _mulatschak.lineup.keys.toList(),
      AppMode.hosnObe => _hosnObe.lineup.keys.toList(),
      _ => const <String>[],
    };

    final startedAt = switch (mode) {
      AppMode.watten => _watten.roundStartedAt,
      _ => DateTime.now(),
    };

    final standings = {
      for (final entry in preview.standings) entry.name: entry.score,
    };

    unawaited(
      _sessions.recordMatch(
        gameType: mode,
        participantIds: participantIds,
        winnerId: preview.winnerId,
        winnerLabel: preview.winnerLabel,
        startedAt: startedAt,
        endedAt: DateTime.now(),
        finalStandings: standings,
      ),
    );

    if (resetBoard) {
      switch (mode) {
        case AppMode.counter:
          _counter.resetBoard();
        case AppMode.watten:
          _watten.resetBoard();
        case AppMode.mulatschak:
          _mulatschak.resetPlayers();
        case AppMode.hosnObe:
          _hosnObe.resetPlayers();
      }
    }
    _showMessage('Partie aufgezeichnet!');
  }

  String? get _mulatschakWinnerName {
    final winnerId = _mulatschak.winner();
    return winnerId == null ? null : _players.displayName(winnerId);
  }

  String? get _hosnObeWinnerName {
    final winnerId = _hosnObe.winner();
    return winnerId == null ? null : _players.displayName(winnerId);
  }

  Future<void> _openHub() async {
    final activeSession = _sessions.activeSession;
    final participantNames = [
      for (final id in activeSession?.participantIds ?? const <String>[])
        _players.displayName(id),
    ];

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (hubContext) => Scaffold(
          appBar: AppBar(title: const Text('Start')),
          body: SafeArea(
            top: false,
            child: HubPage(
              activeSession: activeSession,
              sessionParticipantNames: participantNames,
              onStartSession: () {
                Navigator.of(hubContext).pop();
                _startSession();
              },
              onEndSession: () {
                Navigator.of(hubContext).pop();
                _endSession();
              },
              onModeSelected: (mode) {
                Navigator.of(hubContext).pop();
                _selectMode(mode);
              },
              onOpenStatistics: () {
                Navigator.of(hubContext).pop();
                _openStatistics();
              },
              onOpenPlayers: () {
                Navigator.of(hubContext).pop();
                _openPlayers();
              },
              pastSessionCount: _sessions.pastSessions.length,
            ),
          ),
        ),
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  // MARK: - Zähler

  bool _isCounterNameValid(String name) {
    return CounterHelper.isNameValid(name, _counter.counters.keys);
  }

  void _showAddCounterDialog() {
    AppDialogs.showAddItemDialog(
      context: context,
      title: 'Zähler hinzufügen',
      hintText: 'Zählername',
      isValidName: _isCounterNameValid,
      onAdd: _counter.addCounter,
    );
  }

  void _showRenameCounterDialog(String oldName) {
    AppDialogs.showRenameItemDialog(
      context: context,
      title: 'Zähler umbenennen',
      initialValue: oldName,
      hintText: 'Neuer Zählername',
      duplicateNameMessage: 'Dieser Zählername darf nur einmal vergeben werden.',
      isValidName: (newName) {
        return NameUtils.isUniqueExcept(newName, _counter.counters.keys, oldName);
      },
      onRename: (newName) {
        if (newName != oldName) {
          _counter.renameCounter(oldName, newName);
        }
      },
    );
  }

  void _showDeleteCounterDialog(String counterName) {
    if (_counter.counters.length <= 1) {
      _showMessage('Es muss mindestens ein Zähler übrig bleiben.');
      return;
    }
    AppDialogs.showDeleteItemDialog(
      context: context,
      title: 'Zähler löschen',
      itemName: counterName,
      onDelete: _counter.deleteCounter,
    );
  }

  // MARK: - Watten

  bool _isWattenGameNameValid(String name) {
    return WattenHelper.isGameNameValid(name, _watten.games.keys);
  }

  void _showAddWattenGameDialog() {
    AppDialogs.showAddItemDialog(
      context: context,
      title: 'Spiel hinzufügen',
      hintText: 'Spielname',
      isValidName: _isWattenGameNameValid,
      onAdd: _watten.addGame,
    );
  }

  void _showRenameWattenGameDialog(String oldName) {
    AppDialogs.showRenameItemDialog(
      context: context,
      title: 'Spiel umbenennen',
      initialValue: oldName,
      hintText: 'Neuer Spielname',
      duplicateNameMessage: 'Dieser Spielname darf nur einmal vergeben werden.',
      isValidName: (newName) {
        return NameUtils.isUniqueExcept(newName, _watten.games.keys, oldName);
      },
      onRename: (newName) {
        if (newName != oldName) {
          _watten.renameGame(oldName, newName);
        }
      },
    );
  }

  void _showDeleteWattenGameDialog(String gameName) {
    if (_watten.games.length <= 1) {
      _showMessage('Es muss mindestens ein Spiel übrig bleiben.');
      return;
    }
    AppDialogs.showDeleteItemDialog(
      context: context,
      title: 'Spiel löschen',
      itemName: gameName,
      onDelete: _watten.deleteGame,
    );
  }

  // MARK: - Mulatschak / Hosn Obe

  // MARK: - Drawer

  List<Widget> _buildDrawerExtraActions() {
    return [
      ListTile(
        leading: const Icon(Icons.home_outlined),
        title: const Text('Start'),
        onTap: () {
          Navigator.of(context).pop();
          _openHub();
        },
      ),
      ListTile(
        leading: const Icon(Icons.bar_chart_outlined),
        title: const Text('Statistiken'),
        onTap: () {
          Navigator.of(context).pop();
          _openStatistics();
        },
      ),
      ListTile(
        leading: const Icon(Icons.history),
        title: const Text('Spielabende'),
        onTap: () {
          Navigator.of(context).pop();
          _openPastSessions();
        },
      ),
      ListTile(
        leading: const Icon(Icons.groups_outlined),
        title: const Text('Spieler verwalten'),
        onTap: () {
          Navigator.of(context).pop();
          _openPlayers();
        },
      ),
    ];
  }

  Widget _buildModeDrawer(AppMode mode) {
    switch (mode) {
      case AppMode.counter:
        return CounterDrawer(
          items: _counter.counters.keys.toList(),
          selectedItem: _counter.currentCounter,
          addButtonLabel: 'Neuer Zähler',
          addButtonIcon: Icons.add,
          closeDrawerOnAdd: true,
          enableReorder: true,
          onAddNewItem: _showAddCounterDialog,
          onSelectItem: _counter.selectCounter,
          onRenameItem: _showRenameCounterDialog,
          onDeleteItem: _showDeleteCounterDialog,
          onReorderItems: _counter.reorderCounters,
          extraActions: _buildDrawerExtraActions(),
          onOpenSettings: _openSettings,
        );
      case AppMode.watten:
        return CounterDrawer(
          items: _watten.games.keys.toList(),
          selectedItem: _watten.currentGame,
          addButtonLabel: 'Neues Spiel',
          addButtonIcon: Icons.add,
          closeDrawerOnAdd: true,
          enableReorder: true,
          onAddNewItem: _showAddWattenGameDialog,
          onSelectItem: _watten.selectGame,
          onRenameItem: _showRenameWattenGameDialog,
          onDeleteItem: _showDeleteWattenGameDialog,
          onReorderItems: _watten.reorderGames,
          extraActions: _buildDrawerExtraActions(),
          onOpenSettings: _openSettings,
        );
      case AppMode.mulatschak:
      case AppMode.hosnObe:
        final lineup = mode == AppMode.mulatschak
            ? _mulatschak.lineup
            : _hosnObe.lineup;
        final currentPlayerId = mode == AppMode.mulatschak
            ? _mulatschak.currentPlayerId
            : _hosnObe.currentPlayerId;

        return CounterDrawer(
          items: [
            for (final playerId in lineup.keys)
              _players.displayName(playerId),
          ],
          selectedItem: _players.displayName(currentPlayerId),
          addButtonLabel: 'Spieler hinzufügen',
          addButtonIcon: Icons.person_add_alt_1,
          closeDrawerOnAdd: true,
          enableReorder: false,
          onAddNewItem: _openPlayers,
          onSelectItem: (name) {
            for (final player in _players.players) {
              if (player.displayName == name) {
                if (mode == AppMode.mulatschak) {
                  _mulatschak.selectPlayer(player.id);
                } else {
                  _hosnObe.selectPlayer(player.id);
                }
                break;
              }
            }
          },
          onRenameItem: (_) => _openPlayers(),
          onDeleteItem: (_) => _openPlayers(),
          onReorderItems: (_, _) {},
          extraActions: _buildDrawerExtraActions(),
          onOpenSettings: _openSettings,
        );
    }
  }

  Widget _buildEndDrawer(AppMode mode) {
    if (mode == AppMode.counter && _settings.counterHistoryEnabled) {
      return CounterHistoryDrawer(
        currentCounter: _counter.currentCounter,
        currentHistory:
            _counter.counterHistory[_counter.currentCounter] ??
            const <String>[],
      );
    }
    if (mode == AppMode.mulatschak && _settings.mulatschakHistoryEnabled) {
      return MulatschakHistoryDrawer(history: _mulatschak.historyEntries);
    }
    return const SizedBox.shrink();
  }

  bool _hasEndDrawer(AppMode mode) {
    return mode == AppMode.counter && _settings.counterHistoryEnabled ||
        mode == AppMode.mulatschak && _settings.mulatschakHistoryEnabled;
  }

  // MARK: - AppBar

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      elevation: 0,
      scrolledUnderElevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      title: Text(widget.appMode.label),
      actions: [
        IconButton(
          icon: const Icon(Icons.home_outlined),
          tooltip: 'Start',
          onPressed: _openHub,
        ),
        if (widget.appMode == AppMode.watten)
          IconButton(
            icon: Icon(
              _watten.tableMode
                  ? Icons.compare_arrows
                  : Icons.compare_arrows_outlined,
            ),
            tooltip: 'Tischmodus',
            onPressed: () => _watten.setTableMode(!_watten.tableMode),
          ),
        if (widget.appMode == AppMode.counter && _settings.counterHistoryEnabled)
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Zähler-Verlauf',
            onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
          ),
        if (widget.appMode == AppMode.mulatschak &&
            _settings.mulatschakHistoryEnabled)
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Mulatschak-Verlauf',
            onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
          ),
        IconButton(
          icon: const Icon(Icons.undo),
          tooltip: 'Rückgängig',
          onPressed: historyFor(widget.appMode).canUndo
              ? historyFor(widget.appMode).undo
              : null,
        ),
        IconButton(
          icon: const Icon(Icons.redo),
          tooltip: 'Wiederholen',
          onPressed: historyFor(widget.appMode).canRedo
              ? historyFor(widget.appMode).redo
              : null,
        ),
        IconButton(
          icon: const Icon(Icons.emoji_events_outlined),
          tooltip: 'Partie abschließen',
          onPressed: _showFinishMatchSheet,
        ),
      ],
    );
  }

  // MARK: - Body

  Widget _buildBody() {
    switch (widget.appMode) {
      case AppMode.counter:
        return CounterBody(
          isLoading: !_ready,
          counterName: _counter.currentCounter,
          score: _counter.counters[_counter.currentCounter] ?? 0,
          onIncrement: _counter.increment,
          onDecrement: _counter.decrement,
          onReset: _counter.reset,
        );
      case AppMode.watten:
        return WattenBody(
          isLoading: !_ready,
          gameName: _watten.currentGame,
          currentGame:
              _watten.games[_watten.currentGame] ??
              const WattenGame(me: 0, you: 0),
          selectedSide: _watten.selectedSide,
          winner: _watten.winner(),
          tableMode: _watten.tableMode,
          onSelectedSideChanged: _watten.selectSide,
          onScoreChanged: _watten.changeScore,
          onResetSelectedSide: _watten.resetSelectedSide,
          onTableModeChanged: _watten.setTableMode,
        );
      case AppMode.mulatschak:
        return MulatschakBody(
          isLoading: !_ready,
          scores: _mulatschak.lineup,
          currentPlayerId: _mulatschak.currentPlayerId,
          nameOf: _players.displayName,
          multiplier: _mulatschak.multiplier,
          winner: _mulatschakWinnerName,
          onPlayerSelected: _mulatschak.selectPlayer,
          onScoreChanged: _mulatschak.changeScore,
          onMultiplierChanged: _mulatschak.setMultiplier,
          onResetPlayers: _mulatschak.resetPlayers,
          onAddPlayer: _openPlayers,
        );
      case AppMode.hosnObe:
        return HosnObeBody(
          isLoading: !_ready,
          scores: _hosnObe.lineup,
          currentPlayerId: _hosnObe.currentPlayerId,
          nameOf: _players.displayName,
          winner: _hosnObeWinnerName,
          onPlayerSelected: _hosnObe.selectPlayer,
          onScoreChanged: _hosnObe.changeScore,
          onResetPlayers: _hosnObe.resetPlayers,
          onAddPlayer: _openPlayers,
        );
    }
  }

  // MARK: - Build

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!_settings.onboardingCompleted) {
      return OnboardingPage(
        onModeSelected: (mode) {
          _settings.setOnboardingCompleted();
          _selectMode(mode);
        },
        onSkip: () {
          _settings.setOnboardingCompleted();
        },
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobileDrawerGesture = ResponsiveUtils.isMobilePlatform;

    return ListenableBuilder(
      listenable: Listenable.merge([
        forMode(widget.appMode),
        historyFor(widget.appMode),
        _settings,
      ]),
      builder: (context, _) {
        return Scaffold(
          key: _scaffoldKey,
          resizeToAvoidBottomInset: false,
          appBar: _buildAppBar(),
          drawer: _buildModeDrawer(widget.appMode),
          endDrawer: _hasEndDrawer(widget.appMode)
              ? _buildEndDrawer(widget.appMode)
              : null,
          drawerEdgeDragWidth: isMobileDrawerGesture
              ? screenWidth * 0.5
              : null,
          body: SafeArea(top: false, child: _buildBody()),
        );
      },
    );
  }
}
