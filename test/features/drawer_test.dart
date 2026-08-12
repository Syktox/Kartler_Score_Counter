import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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

      await tester.tap(
        find.descendant(
          of: find.widgetWithText(ListTile, 'Ben'),
          matching: find.text('Mitspielen'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Fertig'));
      await tester.pumpAndSettle();

      final prefs = await SharedPreferences.getInstance();
      expect(jsonDecode(prefs.getString('mulatschak_lineup')!), {'p1': 21});
      expect(find.text('Ben'), findsNothing);
    });
  });
}
