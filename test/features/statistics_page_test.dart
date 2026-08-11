import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kartler/core/haptics_service.dart';
import 'package:kartler/features/players/players_controller.dart';
import 'package:kartler/features/statistics/statistics_calculator.dart';
import 'package:kartler/features/statistics/statistics_page.dart';
import 'package:kartler/models/app_mode.dart';
import 'package:kartler/models/completed_match.dart';
import 'package:kartler/models/game_session.dart';
import 'package:kartler/persistence/repositories/player_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/pump_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late PlayersController players;

  setUp(() {
    SharedPreferences.setMockInitialValues(playerPrefs());
    players = PlayersController(
      repository: const PlayerRepository(),
      haptics: HapticsService(isEnabled: () => false),
    );
  });

  Future<void> pumpStats(
    WidgetTester tester,
    List<CompletedMatch> matches,
  ) async {
    await players.load();
    final result = StatisticsResult(
      totalMatches: matches.length,
      leaderboard: const [],
      matchesPerMode: const {},
      mostPlayedMode: null,
      lastSession: null,
      totalSessions: 0,
      biggestWinMargin: 0,
      recentMatches: matches,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: StatisticsPage(
          result: result,
          players: players,
          sessions: const <GameSession>[],
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  CompletedMatch match({String? winnerId, String? winnerLabel}) {
    return CompletedMatch(
      id: 'm1',
      sessionId: 's1',
      gameType: AppMode.mulatschak,
      participantIds: const ['p1', 'p2'],
      winnerId: winnerId,
      winnerLabel: winnerLabel,
      startedAt: DateTime(2026, 8, 1, 20, 0),
      endedAt: DateTime(2026, 8, 1, 20, 30),
      finalStandings: {'p1': 21, 'p2': 7},
    );
  }

  testWidgets('recent match shows player names instead of raw ids', (
    tester,
  ) async {
    await pumpStats(tester, [match(winnerId: 'p1')]);

    expect(find.text('Mulatschak · Anna gewinnt'), findsOneWidget);
    expect(find.textContaining('p1'), findsNothing);
  });

  testWidgets('recent match without global winner shows the label', (
    tester,
  ) async {
    await pumpStats(tester, [match(winnerLabel: 'Nord')]);

    expect(find.text('Mulatschak · Nord gewinnt'), findsOneWidget);
  });

  testWidgets('recent match without a winner is shown as draw', (tester) async {
    await pumpStats(tester, [match()]);

    expect(find.text('Mulatschak · — gewinnt'), findsOneWidget);
  });
}
