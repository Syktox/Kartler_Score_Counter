import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kartler/core/haptics_service.dart';
import 'package:kartler/features/game_session/sessions_list_page.dart';
import 'package:kartler/features/players/players_controller.dart';
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

  GameSession session({
    required String id,
    required DateTime start,
    DateTime? end,
    List<String> matchIds = const [],
  }) {
    return GameSession(
      id: id,
      startTime: start,
      endTime: end,
      participantIds: const ['p1', 'p2'],
      matchIds: matchIds,
    );
  }

  CompletedMatch match(String id) {
    return CompletedMatch(
      id: id,
      sessionId: 's1',
      gameType: AppMode.watten,
      participantIds: const ['p1', 'p2'],
      winnerId: 'p1',
      startedAt: DateTime(2026, 8, 1, 20, 0),
      endedAt: DateTime(2026, 8, 1, 20, 30),
      finalStandings: {'p1': 2, 'p2': 1},
    );
  }

  Future<void> pumpList(
    WidgetTester tester, {
    required List<GameSession> sessions,
    List<CompletedMatch> Function(String sessionId)? matchesForSession,
  }) async {
    await players.load();
    await tester.pumpWidget(
      MaterialApp(
        home: SessionsListPage(
          sessions: sessions,
          players: players,
          matchesForSession:
              matchesForSession ??
              ((sessionId) => [
                for (final m in [match('m1')])
                  if (m.sessionId == sessionId) m,
              ]),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('sorts sessions newest first without mutating the input', (
    tester,
  ) async {
    final older = session(id: 's_old', start: DateTime(2026, 1, 1));
    final newer = session(id: 's_new', start: DateTime(2026, 6, 1));
    final input = [older, newer];

    await pumpList(tester, sessions: input);

    expect(find.text('01.06.2026'), findsOneWidget);
    expect(find.text('01.01.2026'), findsOneWidget);

    final firstDate = tester.getTopLeft(find.text('01.06.2026')).dy;
    final secondDate = tester.getTopLeft(find.text('01.01.2026')).dy;
    expect(firstDate, lessThan(secondDate));

    expect(input.first, older);
    expect(input.last, newer);
  });

  testWidgets('shows an empty state without past sessions', (tester) async {
    await pumpList(tester, sessions: const []);

    expect(
      find.text('Noch keine abgeschlossenen Spielabende.'),
      findsOneWidget,
    );
  });

  testWidgets('session detail shows recorded matches instead of raw IDs', (
    tester,
  ) async {
    final s = session(
      id: 's1',
      start: DateTime(2026, 8, 1),
      end: DateTime(2026, 8, 1, 22),
      matchIds: const ['m1'],
    );

    await pumpList(
      tester,
      sessions: [s],
      matchesForSession: (sessionId) =>
          sessionId == 's1' ? [match('m1')] : const [],
    );

    await tester.tap(find.text('01.08.2026'));
    await tester.pumpAndSettle();

    expect(find.text('Aufgezeichnete Partien'), findsOneWidget);
    expect(find.text('Watten'), findsOneWidget);
    expect(find.text('Sieger: Anna'), findsOneWidget);
    expect(find.text('m1'), findsNothing);
  });
}
