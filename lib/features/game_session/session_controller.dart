import 'dart:async';

import '../../core/haptics_service.dart';
import '../../core/id_generator.dart';
import '../../models/app_mode.dart';
import '../../models/completed_match.dart';
import '../../models/game_session.dart';
import '../../persistence/repositories/match_history_repository.dart';
import '../../persistence/repositories/session_repository.dart';
import '../feature_controller.dart';

/// Verwaltet Spielabende (GameSessions) und die Match-History.
class SessionController extends FeatureController {
  SessionController({
    required SessionRepository sessionRepository,
    required MatchHistoryRepository matchRepository,
    required HapticsService haptics,
  }) : _sessionRepository = sessionRepository,
       _matchRepository = matchRepository,
       _haptics = haptics;

  final SessionRepository _sessionRepository;
  final MatchHistoryRepository _matchRepository;
  final HapticsService _haptics;

  List<GameSession> _sessions = const [];
  List<CompletedMatch> _matches = const [];

  List<GameSession> get sessions => List.unmodifiable(_sessions);
  List<CompletedMatch> get matches => List.unmodifiable(_matches);

  GameSession? get activeSession {
    for (final session in _sessions) {
      if (session.isActive) {
        return session;
      }
    }
    return null;
  }

  List<GameSession> get pastSessions =>
      _sessions.where((session) => !session.isActive).toList(growable: false);

  @override
  Future<void> load() async {
    _sessions = await _sessionRepository.loadSessions();
    _matches = await _matchRepository.loadMatches();
    isLoading = false;
  }

  /// Startet einen neuen Spielabend mit den gewählten Teilnehmern.
  Future<GameSession> startSession(List<String> participantIds) async {
    final session = GameSession(
      id: IdGenerator.newId(),
      startTime: DateTime.now(),
      participantIds: List<String>.from(participantIds),
    );
    _sessions = [..._sessions, session];
    notifyListeners();
    await _persistSessions();
    await _haptics.heavy();
    return session;
  }

  /// Beendet den aktiven Spielabend.
  Future<GameSession?> endSession() async {
    final session = activeSession;
    if (session == null) {
      return null;
    }
    final ended = session.copyWith(endTime: DateTime.now());
    _sessions = [
      for (final entry in _sessions)
        if (entry.id == ended.id) ended else entry,
    ];
    notifyListeners();
    await _persistSessions();
    await _haptics.heavy();
    return ended;
  }

  /// Zeichnet eine abgeschlossene Partie auf und hängt sie an den aktiven
  /// Spielabend an (falls einer läuft).
  Future<CompletedMatch> recordMatch({
    required AppMode gameType,
    required List<String> participantIds,
    String? winnerId,
    String? winnerLabel,
    required DateTime startedAt,
    required DateTime endedAt,
    required Map<String, int> finalStandings,
  }) async {
    final session = activeSession;
    final match = CompletedMatch(
      id: IdGenerator.newId(),
      sessionId: session?.id,
      gameType: gameType,
      participantIds: List<String>.from(participantIds),
      winnerId: winnerId,
      winnerLabel: winnerLabel,
      startedAt: startedAt,
      endedAt: endedAt,
      finalStandings: Map<String, int>.from(finalStandings),
    );
    _matches = [..._matches, match];
    if (session != null) {
      _sessions = [
        for (final entry in _sessions)
          if (entry.id == session.id)
            entry.withMatchRecorded(match.id)
          else
            entry,
      ];
    }
    notifyListeners();
    await _persistMatches();
    await _persistSessions();
    await _haptics.heavy();
    return match;
  }

  GameSession? sessionById(String id) {
    for (final session in _sessions) {
      if (session.id == id) {
        return session;
      }
    }
    return null;
  }

  List<CompletedMatch> matchesForSession(String sessionId) {
    return _matches
        .where((match) => match.sessionId == sessionId)
        .toList(growable: false);
  }

  Future<void> _persistSessions() {
    return _sessionRepository.saveSessions(_sessions);
  }

  Future<void> _persistMatches() {
    return _matchRepository.saveMatches(_matches);
  }
}
