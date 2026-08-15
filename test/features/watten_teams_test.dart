import 'dart:convert';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/pump_app.dart';

Map<String, Object> fourPlayerPrefs() {
  return {
    ...wattenPrefs(),
    'players': jsonEncode([
      {'id': 'p1', 'name': 'Anna', 'createdAt': '2024-01-01T00:00:00.000Z'},
      {'id': 'p2', 'name': 'Ben', 'createdAt': '2024-01-01T00:00:00.000Z'},
      {'id': 'p3', 'name': 'Carla', 'createdAt': '2024-01-01T00:00:00.000Z'},
      {'id': 'p4', 'name': 'Dora', 'createdAt': '2024-01-01T00:00:00.000Z'},
    ]),
  };
}

Finder sidePillOf(String playerName, String side) {
  return find.descendant(
    of: find.widgetWithText(ListTile, playerName),
    matching: find.widgetWithText(OutlinedButton, side),
  );
}

Future<void> openWattenTeamSheet(WidgetTester tester) async {
  await openDrawer(tester);
  await tester.tap(find.text('Wer spielt?'));
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Watten teams', () {
    testWidgets('assigns players to the two sides and persists the teams', (
      tester,
    ) async {
      await pumpApp(tester, prefs: {...wattenPrefs(), ...playerPrefs()});

      await openWattenTeamSheet(tester);

      await tester.tap(sidePillOf('Anna', 'Ich'));
      await tester.tap(sidePillOf('Ben', 'Du'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Fertig'));
      await tester.pumpAndSettle();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('watten_team_me'), jsonEncode(['p1']));
      expect(prefs.getString('watten_team_you'), jsonEncode(['p2']));

      expect(find.text('Anna'), findsOneWidget);
      expect(find.text('Ben'), findsOneWidget);
    });

    testWidgets('allows at most two players per team', (tester) async {
      await pumpApp(tester, prefs: fourPlayerPrefs());

      await openWattenTeamSheet(tester);

      await tester.tap(sidePillOf('Anna', 'Ich'));
      await tester.tap(sidePillOf('Ben', 'Ich'));
      await tester.pumpAndSettle();

      final carlaIchPill = sidePillOf('Carla', 'Ich');
      expect(tester.widget<OutlinedButton>(carlaIchPill).onPressed, isNull);

      final carlaDuPill = sidePillOf('Carla', 'Du');
      expect(tester.widget<OutlinedButton>(carlaDuPill).onPressed, isNotNull);

      await tester.tap(carlaDuPill);
      await tester.tap(sidePillOf('Dora', 'Du'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Fertig'));
      await tester.pumpAndSettle();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('watten_team_me'), jsonEncode(['p1', 'p2']));
      expect(prefs.getString('watten_team_you'), jsonEncode(['p3', 'p4']));
    });

    testWidgets('assigns available players by dragging them into a team', (
      tester,
    ) async {
      await pumpApp(tester, prefs: {...wattenPrefs(), ...playerPrefs()});

      await openWattenTeamSheet(tester);

      final gesture = await tester.startGesture(
        tester.getCenter(find.widgetWithText(ListTile, 'Anna')),
      );
      await tester.pump(kLongPressTimeout + const Duration(milliseconds: 100));
      await gesture.moveTo(
        tester.getCenter(find.byKey(const ValueKey('watten-team-me'))),
      );
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Fertig'));
      await tester.pumpAndSettle();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('watten_team_me'), jsonEncode(['p1']));
    });

    testWidgets('shows the team names as side titles and winner', (
      tester,
    ) async {
      await pumpApp(
        tester,
        prefs: {
          ...fourPlayerPrefs(),
          'watten_lineup': jsonEncode({
            'Spiel 1': {'me': 11, 'you': 3},
          }),
          'watten_team_me': jsonEncode(['p1', 'p2']),
          'watten_team_you': jsonEncode(['p3']),
        },
      );

      expect(find.text('Anna & Ben'), findsOneWidget);
      expect(find.text('Carla'), findsOneWidget);
      expect(find.text('Gewinner'), findsOneWidget);
      expect(find.text('Anna & Ben gewinnen!'), findsNothing);
      expect(find.text('Ich gewinnt!'), findsNothing);
    });

    testWidgets('removes a deleted player from the teams', (tester) async {
      await pumpApp(
        tester,
        prefs: {
          ...wattenPrefs(),
          ...playerPrefs(),
          'watten_team_me': jsonEncode(['p1']),
          'watten_team_you': jsonEncode(['p2']),
        },
      );

      await openDrawer(tester);
      await tester.tap(find.text('Spieler verwalten'));
      await tester.pumpAndSettle();

      await tester.tap(
        find.descendant(
          of: find.widgetWithText(ListTile, 'Ben'),
          matching: find.byIcon(Icons.delete_outline),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Löschen'));
      await tester.pumpAndSettle();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('watten_team_you'), jsonEncode([]));
    });
  });
}
