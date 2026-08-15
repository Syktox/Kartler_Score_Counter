import 'dart:async';

import 'package:flutter/material.dart';

import '../../commands/command_history.dart';
import '../../core/haptics_service.dart';
import '../../features/counter/counter_body.dart';
import '../../features/counter/counter_controller.dart';
import '../../features/counter/counter_helper.dart';
import '../../features/game_session/session_controller.dart';
import '../../features/game_session/session_summary_page.dart';
import '../../features/game_session/sessions_list_page.dart';
import '../../features/hosn_obe/hosn_obe_body.dart';
import '../../features/hosn_obe/hosn_obe_controller.dart';
import '../../features/mulatschak/mulatschak_body.dart';
import '../../features/mulatschak/mulatschak_controller.dart';
import '../../features/players/lineup_selection_sheet.dart';
import '../../features/players/player_management_page.dart';
import '../../features/players/players_controller.dart';
import '../../features/settings/settings_controller.dart';
import '../../features/settings/settings_page.dart';
import '../../features/statistics/statistics_calculator.dart';
import '../../features/statistics/statistics_page.dart';
import '../../features/watten/watten_body.dart';
import '../../features/watten/watten_controller.dart';
import '../../features/watten/watten_team_sheet.dart';
import '../../features/winners/winners_dialog.dart';
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
import '../../widgets/recorded_bubble.dart';
import '../../widgets/watten_history_drawer.dart';
import 'hub_page.dart';
import 'match_recorder.dart';
import 'start_screen.dart';

/// Zentrale Shell der App.
///
/// Erstellt und lädt alle Feature-Controller, verdrahtet die Spielmodi und
/// koordiniert Navigation (Hub, StartScreen, Verwaltung), Undo/Redo sowie
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
  late final MatchRecorder _recorder;
  late final HapticsService _haptics;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final RecordedBubbleHost _bubbleHost = RecordedBubbleHost();
  bool _ready = false;
  bool _startScreenDone = false;

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
    _recorder = MatchRecorder(
      counter: _counter,
      watten: _watten,
      mulatschak: _mulatschak,
      hosnObe: _hosnObe,
      players: _players,
      sessions: _sessions,
    );

    _settings.addListener(_syncSettingsToApp);
    _syncSettingsToApp();
    _loadAll();
  }

  @override
  void dispose() {
    _bubbleHost.dispose();
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

  /// Beendet den StartScreen für diese Sitzung. Ohne Modusauswahl (Skip)
  /// bleibt der zuletzt verwendete Modus aktiv.
  void _finishStartScreen(AppMode? mode) {
    setState(() {
      _startScreenDone = true;
    });
    if (mode != null) {
      _selectMode(mode);
    }
  }

  Future<void> _openSettings() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            SettingsPage(settings: _settings, onDataImported: _loadAll),
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
          watten: _watten,
          confirmDelete: _settings.playerDeleteConfirmationEnabled,
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
          matchesForSession: _sessions.matchesForSession,
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

  void _recordMatch(AppMode mode, {required bool resetBoard}) {
    unawaited(_recorder.record(mode, resetBoard: resetBoard));
    _bubbleHost.show(context, 'Partie aufgezeichnet!');
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
    _bubbleHost.show(context, message);
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
      duplicateNameMessage:
          'Dieser Zählername darf nur einmal vergeben werden.',
      isValidName: (newName) {
        return NameUtils.isUniqueExcept(
          newName,
          _counter.counters.keys,
          oldName,
        );
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

  /// Anzeigename einer Watten-Seite: Teamnamen, falls Teams gewählt wurden.
  String _wattenSideLabel(WattenSide side) {
    final ids = side == WattenSide.me ? _watten.meTeam : _watten.youTeam;
    if (ids.isEmpty) {
      return side.label;
    }
    return ids.map(_players.displayName).join(' & ');
  }

  Future<void> _openWattenTeamPicker() async {
    final teams = await showModalBottomSheet<WattenTeams>(
      context: context,
      isScrollControlled: true,
      builder: (_) => WattenTeamSheet(
        players: _players.players,
        meTeam: _watten.meTeam,
        youTeam: _watten.youTeam,
      ),
    );
    if (teams == null) {
      return;
    }
    _watten.setTeams(me: teams.me, you: teams.you);
  }

  /// Startet eine neue Watten-Partie: Die aktuelle Partie wird (sofern schon
  /// Punkte erzielt wurden) in den Statistiken aufgezeichnet, danach beginnt
  /// eine frische Partie bei 0:0.
  void _startNewWattenGame() {
    final game =
        _watten.games[_watten.currentGame] ?? const WattenGame(me: 0, you: 0);
    if (game.me == 0 && game.you == 0) {
      return;
    }
    _recordMatch(AppMode.watten, resetBoard: true);
  }

  /// Startet ein neues Mulatschak-Spiel wie beim Watten: Die aktuelle Partie
  /// wird (sofern schon gespielt) in den Statistiken aufgezeichnet, danach
  /// starten alle Spieler wieder bei der Startpunktzahl.
  void _startNewMulatschakGame() {
    final startingScore = _settings.ruleProfile.mulatschakStartingScore;
    if (_mulatschak.lineup.isEmpty ||
        _mulatschak.lineup.values.every((value) => value == startingScore)) {
      return;
    }
    _recordMatch(AppMode.mulatschak, resetBoard: true);
  }

  /// Startet ein neues Hosn-Obe-Spiel wie beim Watten: Die aktuelle Partie
  /// wird (sofern schon gespielt) aufgezeichnet, danach starten alle Spieler
  /// wieder mit der Startanzahl an Leben.
  void _startNewHosnObeGame() {
    final startingLives = _settings.ruleProfile.hosnObeStartingLives;
    if (_hosnObe.lineup.isEmpty ||
        _hosnObe.lineup.values.every((value) => value == startingLives)) {
      return;
    }
    _recordMatch(AppMode.hosnObe, resetBoard: true);
  }

  /// Startet einen neuen Zähler-Durchgang: Alle Zähler werden auf 0 gesetzt.
  /// Zähler werden nicht in den Statistiken aufgezeichnet.
  void _startNewCounterGame() {
    if (_counter.counters.values.every((value) => value == 0)) {
      return;
    }
    _counter.resetBoard(clearHistory: true);
  }

  // MARK: - Hosn Obe

  // MARK: - Drawer

  void _showWinnersDialog() {
    showDialog<void>(
      context: context,
      builder: (_) => WinnersDialog(
        matches: _sessions.matches,
        displayName: _players.displayName,
      ),
    );
  }

  /// Öffnet die Mitspieler-Auswahl für Mulatschak oder Hosn Obe.
  Future<void> _openLineupPicker(AppMode mode) async {
    final isMulatschak = mode == AppMode.mulatschak;
    final current = isMulatschak ? _mulatschak.lineup : _hosnObe.lineup;
    final selected = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      builder: (_) => LineupSelectionSheet(
        players: _players.players,
        lineup: current.keys.toList(),
      ),
    );
    if (selected == null) {
      return;
    }
    if (isMulatschak) {
      _mulatschak.setLineup(selected);
    } else {
      _hosnObe.setLineup(selected);
    }
  }

  Widget _buildDrawerStartAction() {
    return ListTile(
      leading: const Icon(Icons.home_outlined),
      title: const Text('Startseite'),
      onTap: () {
        Navigator.of(context).pop();
        _openHub();
      },
    );
  }

  List<Widget> _buildDrawerExtraActions(AppMode mode) {
    return [
      if (mode != AppMode.counter)
        ListTile(
          leading: const Icon(Icons.groups_outlined),
          title: const Text('Wer spielt?'),
          onTap: () {
            Navigator.of(context).pop();
            if (mode == AppMode.watten) {
              _openWattenTeamPicker();
            } else {
              _openLineupPicker(mode);
            }
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
          addButtonLabel: 'Neues Spiel',
          addButtonIcon: Icons.play_circle_outline,
          closeDrawerOnAdd: true,
          enableReorder: true,
          showAddButton: false,
          onAddNewItem: _startNewCounterGame,
          onSelectItem: _counter.selectCounter,
          onRenameItem: _showRenameCounterDialog,
          onDeleteItem: _showDeleteCounterDialog,
          onReorderItems: _counter.reorderCounters,
          secondaryActionLabel: 'Neuer Zähler',
          secondaryActionIcon: Icons.add,
          onSecondaryAction: _showAddCounterDialog,
          extraActions: const [],
          onOpenSettings: _openSettings,
        );
      case AppMode.watten:
      case AppMode.mulatschak:
      case AppMode.hosnObe:
        return CounterDrawer(
          items: const [],
          selectedItem: '',
          addButtonLabel: 'Neues Spiel',
          addButtonIcon: Icons.play_circle_outline,
          closeDrawerOnAdd: true,
          onAddNewItem: switch (mode) {
            AppMode.watten => _startNewWattenGame,
            AppMode.mulatschak => _startNewMulatschakGame,
            AppMode.hosnObe => _startNewHosnObeGame,
            AppMode.counter => _startNewCounterGame,
          },
          onSelectItem: (_) {},
          onRenameItem: (_) {},
          onDeleteItem: (_) {},
          secondaryActionLabel: 'Siegerübersicht',
          secondaryActionIcon: Icons.emoji_events_outlined,
          onSecondaryAction: _showWinnersDialog,
          topActions: [_buildDrawerStartAction()],
          extraActions: _buildDrawerExtraActions(mode),
          pinExtraActions: false,
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
    if (mode == AppMode.watten && _settings.wattenHistoryEnabled) {
      return WattenHistoryDrawer(
        history: _watten.historyEntries,
        meLabel: _wattenSideLabel(WattenSide.me),
        youLabel: _wattenSideLabel(WattenSide.you),
      );
    }
    return const SizedBox.shrink();
  }

  bool _hasEndDrawer(AppMode mode) {
    return (mode == AppMode.counter && _settings.counterHistoryEnabled) ||
        (mode == AppMode.watten && _settings.wattenHistoryEnabled) ||
        (mode == AppMode.mulatschak && _settings.mulatschakHistoryEnabled);
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
        if (widget.appMode == AppMode.watten &&
            ResponsiveUtils.isHandsetLandscape(MediaQuery.sizeOf(context)))
          IconButton(
            icon: Icon(
              _watten.tableMode
                  ? Icons.compare_arrows
                  : Icons.compare_arrows_outlined,
            ),
            tooltip: 'Tischmodus',
            onPressed: () => _watten.setTableMode(!_watten.tableMode),
          ),
        if (widget.appMode == AppMode.counter &&
            _settings.counterHistoryEnabled)
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Zähler-Verlauf',
            onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
          ),
        if (widget.appMode == AppMode.watten && _settings.wattenHistoryEnabled)
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Watten-Verlauf',
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
          icon: const Icon(Icons.home_outlined),
          tooltip: 'Startseite',
          onPressed: _openHub,
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
          currentGame:
              _watten.games[_watten.currentGame] ??
              const WattenGame(me: 0, you: 0),
          selectedSide: _watten.selectedSide,
          winner: _watten.winner(),
          tableMode: _watten.tableMode,
          winningScore: _settings.ruleProfile.wattenWinningScore,
          meLabel: _wattenSideLabel(WattenSide.me),
          youLabel: _wattenSideLabel(WattenSide.you),
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
          winnerPlayerId: _mulatschak.winner(),
          onPlayerSelected: _mulatschak.selectPlayer,
          onPlayersReordered: _mulatschak.reorderPlayers,
          onScoreChanged: _mulatschak.changeScore,
          onMultiplierChanged: _mulatschak.setMultiplier,
          hasAvailablePlayers: _players.players.isNotEmpty,
          onPickLineup: () => _openLineupPicker(AppMode.mulatschak),
          onAddPlayer: _openPlayers,
        );
      case AppMode.hosnObe:
        return HosnObeBody(
          isLoading: !_ready,
          scores: _hosnObe.lineup,
          currentPlayerId: _hosnObe.currentPlayerId,
          nameOf: _players.displayName,
          winnerPlayerId: _hosnObe.winner(),
          onPlayerSelected: _hosnObe.selectPlayer,
          onScoreChanged: _hosnObe.changeScore,
          hasAvailablePlayers: _players.players.isNotEmpty,
          onPickLineup: () => _openLineupPicker(AppMode.hosnObe),
          onAddPlayer: _openPlayers,
        );
    }
  }

  // MARK: - Build

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobileDrawerGesture = ResponsiveUtils.isMobilePlatform;

    return ListenableBuilder(
      listenable: Listenable.merge([
        forMode(widget.appMode),
        historyFor(widget.appMode),
        _settings,
        _players,
      ]),
      builder: (context, _) {
        if (!_startScreenDone) {
          return StartScreen(
            onModeSelected: (mode) {
              _finishStartScreen(mode);
            },
            onSkip: () {
              _finishStartScreen(null);
            },
          );
        }
        return Scaffold(
          key: _scaffoldKey,
          resizeToAvoidBottomInset: false,
          appBar: _buildAppBar(),
          drawer: _buildModeDrawer(widget.appMode),
          endDrawer: _hasEndDrawer(widget.appMode)
              ? _buildEndDrawer(widget.appMode)
              : null,
          drawerEdgeDragWidth: isMobileDrawerGesture ? screenWidth * 0.5 : null,
          body: SafeArea(top: false, child: _buildBody()),
        );
      },
    );
  }
}
