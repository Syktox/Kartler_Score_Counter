import 'dart:convert';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kartler/features/players/lineup_selection_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/pump_app.dart';

Map<String, dynamic> completedMatch(String id, String gameType) {
  return {
    'id': id,
    'gameType': gameType,
    'participants': <String>[],
    'winnerId': null,
    'winnerLabel': 'Ich',
    'startedAt': '2024-01-01T12:00:00.000',
    'endedAt': '2024-01-01T12:30:00.000',
    'standings': {'Ich': 11, 'Du': 3},
  };
}

Map<String, Object> threePlayerMulatschakPrefs() {
  return {
    ...mulatschakPrefs(lineup: {'p1': 21, 'p2': 21, 'p3': 21}),
    'players': jsonEncode([
      {'id': 'p1', 'name': 'Anna', 'createdAt': '2024-01-01T00:00:00.000Z'},
      {'id': 'p2', 'name': 'Ben', 'createdAt': '2024-01-01T00:00:00.000Z'},
      {'id': 'p3', 'name': 'Cara', 'createdAt': '2024-01-01T00:00:00.000Z'},
    ]),
  };
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Sidebar drawers', () {
    testWidgets('counter drawer offers no new game option', (tester) async {
      await pumpApp(tester, prefs: counterPrefs());

      await openDrawer(tester);

      expect(
        find.descendant(
          of: find.byType(Drawer),
          matching: find.text('Neues Spiel'),
        ),
        findsNothing,
      );
      expect(find.text('Neuer Zähler'), findsOneWidget);
      expect(
        find.descendant(of: find.byType(Drawer), matching: find.text('Punkte')),
        findsOneWidget,
      );
    });

    testWidgets('game modes show new game, previous winners and teammates', (
      tester,
    ) async {
      await pumpApp(tester, prefs: mulatschakPrefs());

      await openDrawer(tester);

      expect(find.text('Neues Spiel'), findsOneWidget);
      expect(find.text('Siegerübersicht'), findsOneWidget);
      expect(find.text('Wer spielt?'), findsOneWidget);
      expect(find.text('Noch keine Partien aufgezeichnet'), findsNothing);
      expect(
        find.descendant(of: find.byType(Drawer), matching: find.text('Anna')),
        findsNothing,
      );
      expect(
        find.descendant(of: find.byType(Drawer), matching: find.text('Ben')),
        findsNothing,
      );
    });

    testWidgets(
      'game modes show lineup picker in the sidebar without players',
      (tester) async {
        await pumpApp(tester, prefs: wattenPrefs());

        await openDrawer(tester);

        expect(find.text('Neues Spiel'), findsOneWidget);
        expect(find.text('Wer spielt?'), findsOneWidget);
        expect(find.text('Spieler verwalten'), findsOneWidget);
      },
    );

    testWidgets('lineup picker does not show an empty-player hint', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LineupSelectionSheet(players: [], lineup: []),
          ),
        ),
      );

      expect(find.text('Wer spielt?'), findsOneWidget);
      expect(find.textContaining('Noch keine Spieler vorhanden'), findsNothing);
    });

    testWidgets('counter drawer only contains counter actions and settings', (
      tester,
    ) async {
      await pumpApp(tester, prefs: counterPrefs());

      await openDrawer(tester);

      for (final label in [
        'Startseite',
        'Statistiken',
        'Spielabende',
        'Spieler verwalten',
      ]) {
        expect(
          find.descendant(of: find.byType(Drawer), matching: find.text(label)),
          findsNothing,
        );
      }
      expect(
        find.byKey(const ValueKey('drawer-settings-footer')),
        findsOneWidget,
      );
    });

    testWidgets('watten drawer does not show recent winners as subtitle', (
      tester,
    ) async {
      await pumpApp(
        tester,
        prefs: {
          ...wattenPrefs(),
          'match_history': jsonEncode([completedMatch('m1', 'watten')]),
        },
      );

      await openDrawer(tester);

      expect(
        find.descendant(of: find.byType(Drawer), matching: find.text('Ich')),
        findsNothing,
      );
    });

    testWidgets('watten history shows recorded score changes', (tester) async {
      await pumpApp(
        tester,
        prefs: {...wattenPrefs(), 'watten_history_enabled': true},
      );

      await tester.tap(find.text('+2'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Watten-Verlauf'));
      await tester.pumpAndSettle();

      final drawer = find.byType(Drawer);
      expect(
        find.descendant(of: drawer, matching: find.text('Watten-Verlauf')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: drawer, matching: find.text('Ich')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: drawer, matching: find.text('+2 Punkte')),
        findsOneWidget,
      );
    });

    testWidgets('winner button opens the dialog with overall and today views', (
      tester,
    ) async {
      await pumpApp(
        tester,
        prefs: {
          ...wattenPrefs(),
          'match_history': jsonEncode([completedMatch('m1', 'watten')]),
        },
      );

      await openDrawer(tester);
      await tester.tap(find.text('Siegerübersicht'));
      await tester.pumpAndSettle();

      final dialog = find.byType(Dialog);
      Finder inDialog(String text) =>
          find.descendant(of: dialog, matching: find.text(text));

      expect(inDialog('Siegerübersicht'), findsOneWidget);
      expect(inDialog('Gesamt'), findsOneWidget);
      expect(inDialog('Heute'), findsOneWidget);
      expect(inDialog('Watten'), findsOneWidget);
      expect(inDialog('Ich'), findsOneWidget);

      await tester.tap(find.text('Heute'));
      await tester.pumpAndSettle();

      expect(inDialog('Noch keine Partien aufgezeichnet.'), findsOneWidget);
    });

    testWidgets('lineup picker removes players from the mulatschak lineup', (
      tester,
    ) async {
      await pumpApp(tester, prefs: mulatschakPrefs());

      await openDrawer(tester);
      await tester.tap(find.text('Wer spielt?'));
      await tester.pumpAndSettle();

      final participationSlider = find.byKey(
        const ValueKey('lineup-participation-p2'),
      );
      final participationSwitch = find.descendant(
        of: participationSlider,
        matching: find.byType(Switch),
      );
      expect(tester.widget<Switch>(participationSwitch).value, isTrue);

      await tester.drag(participationSwitch, const Offset(-80, 0));
      await tester.pumpAndSettle();
      expect(tester.widget<Switch>(participationSwitch).value, isFalse);
      expect(
        find.descendant(
          of: participationSlider,
          matching: find.text('Zuschauen'),
        ),
        findsOneWidget,
      );

      await tester.drag(participationSwitch, const Offset(80, 0));
      await tester.pumpAndSettle();
      expect(tester.widget<Switch>(participationSwitch).value, isTrue);
      expect(
        find.descendant(
          of: participationSlider,
          matching: find.text('Mitspielen'),
        ),
        findsOneWidget,
      );

      await tester.drag(participationSwitch, const Offset(-80, 0));
      await tester.pumpAndSettle();
      expect(tester.widget<Switch>(participationSwitch).value, isFalse);
      await tester.tap(find.text('Fertig'));
      await tester.pumpAndSettle();

      final prefs = await SharedPreferences.getInstance();
      expect(jsonDecode(prefs.getString('mulatschak_lineup')!), {'p1': 21});
      expect(find.text('Ben'), findsNothing);
    });

    testWidgets('lineup picker keeps a players place when toggled back on', (
      tester,
    ) async {
      await pumpApp(tester, prefs: threePlayerMulatschakPrefs());

      await openDrawer(tester);
      await tester.tap(find.text('Wer spielt?'));
      await tester.pumpAndSettle();

      final participationSlider = find.byKey(
        const ValueKey('lineup-participation-p2'),
      );
      final participationSwitch = find.descendant(
        of: participationSlider,
        matching: find.byType(Switch),
      );

      await tester.drag(participationSwitch, const Offset(-80, 0));
      await tester.pumpAndSettle();
      await tester.drag(participationSwitch, const Offset(80, 0));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Fertig'));
      await tester.pumpAndSettle();

      final prefs = await SharedPreferences.getInstance();
      final lineup =
          jsonDecode(prefs.getString('mulatschak_lineup')!)
              as Map<String, dynamic>;
      expect(lineup.keys.toList(), ['p1', 'p2', 'p3']);
    });

    testWidgets('lineup picker reorders players by long pressing a card', (
      tester,
    ) async {
      await pumpApp(tester, prefs: threePlayerMulatschakPrefs());

      await openDrawer(tester);
      await tester.tap(find.text('Wer spielt?'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.drag_indicator), findsNothing);

      final annaCard = find.byKey(const ValueKey('lineup-player-p1'));
      final start = tester.getCenter(annaCard);
      final gesture = await tester.startGesture(start);
      await tester.pump(kLongPressTimeout + const Duration(milliseconds: 100));
      await gesture.moveBy(const Offset(0, 170));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Fertig'));
      await tester.pumpAndSettle();

      final prefs = await SharedPreferences.getInstance();
      final lineup =
          jsonDecode(prefs.getString('mulatschak_lineup')!)
              as Map<String, dynamic>;
      expect(lineup.keys.toList(), ['p2', 'p1', 'p3']);
    });
  });
}
