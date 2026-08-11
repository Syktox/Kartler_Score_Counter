import 'package:flutter_test/flutter_test.dart';
import 'package:kartler/core/haptics_service.dart';
import 'package:kartler/features/game_session/session_controller.dart';
import 'package:kartler/features/statistics/statistics_calculator.dart';
import 'package:kartler/models/app_mode.dart';
import 'package:kartler/models/completed_match.dart';
import 'package:kartler/models/game_session.dart';
import 'package:kartler/persistence/repositories/match_history_repository.dart';
import 'package:kartler/persistence/repositories/session_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SessionController', () {
    late SessionController controller;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      controller = SessionController(
        sessionRepository: const SessionRepository(),
        matchRepository: const MatchHistoryRepository(),
        haptics: HapticsService(isEnabled: () => false),
      );
    });

    test('starts and ends a session and persists it', () async {
      await controller.load();

      final session = await controller.startSession(['p1', 'p2']);
      expect(controller.activeSession?.id, session.id);

      final ended = await controller.endSession();
      expect(ended, isNotNull);
      expect(ended!.isActive, isFalse);
      expect(controller.activeSession, isNull);
      expect(controller.pastSessions.length, 1);
    });

    test('records a match and attaches it to the active session', () async {
      await controller.load();
      await controller.startSession(['p1', 'p2']);

      final match = await controller.recordMatch(
        gameType: AppMode.mulatschak,
        participantIds: const ['p1', 'p2'],
        winnerId: 'p1',
        startedAt: DateTime(2026, 1, 1, 20),
        endedAt: DateTime(2026, 1, 1, 21),
        finalStandings: const {'p1': 21, 'p2': 5},
      );

      expect(controller.matches.length, 1);
      expect(controller.activeSession!.matchIds, contains(match.id));
      expect(controller.matchesForSession(controller.activeSession!.id), hasLength(1));
    });

    test('records a match without an active session', () async {
      await controller.load();

      await controller.recordMatch(
        gameType: AppMode.watten,
        participantIds: const [],
        winnerLabel: 'Wir',
        startedAt: DateTime(2026, 1, 1, 20),
        endedAt: DateTime(2026, 1, 1, 21),
        finalStandings: const {'Wir': 11, 'Die': 8},
      );

      expect(controller.matches.length, 1);
      expect(controller.matches.single.sessionId, isNull);
    });
  });

  group('StatisticsCalculator', () {
    test('computes leaderboard, wins and win rate from matches', () {
      final result = StatisticsCalculator.calculate(
        matches: [
          _match(id: 'm1', winner: 'p1', participants: const ['p1', 'p2']),
          _match(id: 'm2', winner: 'p1', participants: const ['p1', 'p2']),
          _match(id: 'm3', winner: 'p2', participants: const ['p1', 'p2']),
        ],
        sessions: const [],
      );

      expect(result.totalMatches, 3);
      expect(result.leaderboard.length, 2);
      expect(result.leaderboard.first.playerId, 'p1');
      expect(result.leaderboard.first.wins, 2);
      expect(result.leaderboard.first.losses, 1);
      expect(result.leaderboard.first.winRate, closeTo(2 / 3, 0.001));
    });

    test('counts matches per mode and the most played mode', () {
      final result = StatisticsCalculator.calculate(
        matches: [
          _match(id: 'm1', winner: null, participants: const ['p1'], mode: AppMode.watten),
          _match(id: 'm2', winner: null, participants: const ['p1'], mode: AppMode.watten),
          _match(id: 'm3', winner: null, participants: const ['p1'], mode: AppMode.mulatschak),
        ],
        sessions: const [],
      );

      expect(result.matchesPerMode[AppMode.watten], 2);
      expect(result.matchesPerMode[AppMode.mulatschak], 1);
      expect(result.mostPlayedMode, AppMode.watten);
    });

    test('ignores counter matches in the statistics', () {
      final result = StatisticsCalculator.calculate(
        matches: [
          _match(id: 'm1', winner: null, participants: const ['p1'], mode: AppMode.hosnObe),
          _match(
            id: 'm2',
            winner: null,
            participants: const [],
            mode: AppMode.counter,
            standings: const {'Punkte': 15},
          ),
        ],
        sessions: const [],
      );

      expect(result.totalMatches, 1);
      expect(result.matchesPerMode.containsKey(AppMode.counter), isFalse);
      expect(result.mostPlayedMode, AppMode.hosnObe);
    });

    test('tracks the biggest win margin', () {
      final result = StatisticsCalculator.calculate(
        matches: [
          _match(id: 'm1', winner: 'p1', participants: const ['p1', 'p2']),
          _match(
            id: 'm2',
            winner: 'p1',
            participants: const ['p1', 'p2'],
            standings: const {'p1': 21, 'p2': 0},
          ),
        ],
        sessions: const [],
      );

      expect(result.biggestWinMargin, 21);
    });

    test('headToHead counts only shared matches', () {
      final matches = [
        _match(id: 'm1', winner: 'p1', participants: const ['p1', 'p2']),
        _match(id: 'm2', winner: 'p2', participants: const ['p1', 'p2']),
        _match(id: 'm3', winner: 'p1', participants: const ['p1', 'p3']),
      ];

      final result = StatisticsCalculator.headToHead(
        playerA: 'p1',
        playerB: 'p2',
        matches: matches,
      );

      expect(result.total, 2);
      expect(result.aWins, 1);
      expect(result.bWins, 1);
    });

    test('lastSession uses only finished sessions', () {
      final finished = _session(
        id: 's1',
        start: DateTime(2026, 2, 1),
        end: DateTime(2026, 2, 1, 22),
      );
      final result = StatisticsCalculator.calculate(
        matches: const [],
        sessions: [finished, _session(id: 's2', start: DateTime(2026, 2, 2))],
      );

      expect(result.totalSessions, 1);
      expect(result.lastSession?.id, 's1');
    });
  });
}

CompletedMatch _match({
  required String id,
  required String? winner,
  required List<String> participants,
  AppMode mode = AppMode.hosnObe,
  Map<String, int> standings = const {'p1': 3, 'p2': 1},
}) {
  return CompletedMatch(
    id: id,
    gameType: mode,
    participantIds: participants,
    winnerId: winner,
    startedAt: DateTime(2026, 1, 1),
    endedAt: DateTime(2026, 1, 1, 21),
    finalStandings: standings,
  );
}

GameSession _session({
  required String id,
  required DateTime start,
  DateTime? end,
}) {
  return GameSession(
    id: id,
    startTime: start,
    endTime: end,
    participantIds: const [],
  );
}
