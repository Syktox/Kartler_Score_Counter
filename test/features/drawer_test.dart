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
      expect(find.text('Gewinner bisher'), findsOneWidget);
      expect(find.text('Wer spielt mit?'), findsOneWidget);
      expect(find.text('Noch keine Partien aufgezeichnet'), findsOneWidget);
      expect(
        find.descendant(of: find.byType(Drawer), matching: find.text('Anna')),
        findsNothing,
      );
      expect(
        find.descendant(of: find.byType(Drawer), matching: find.text('Ben')),
        findsNothing,
      );
    });

    testWidgets('counter drawer keeps navigation at the bottom', (
      tester,
    ) async {
      await pumpApp(tester, prefs: counterPrefs());

      await openDrawer(tester);

      final settingsFooter = find.byKey(
        const ValueKey('drawer-settings-footer'),
      );
      final extraActions = find.byKey(const ValueKey('drawer-extra-actions'));
      expect(settingsFooter, findsOneWidget);
      expect(extraActions, findsOneWidget);

      final footerTop = tester.getTopLeft(settingsFooter).dy;
      final extrasBottom = tester.getBottomLeft(extraActions).dy;
      expect(extrasBottom, lessThanOrEqualTo(footerTop));
    });

    testWidgets('watten drawer lists the most recent winner', (tester) async {
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
      await tester.tap(find.text('Gewinner bisher'));
      await tester.pumpAndSettle();

      final dialog = find.byType(Dialog);
      Finder inDialog(String text) =>
          find.descendant(of: dialog, matching: find.text(text));

      expect(inDialog('Gewinner bisher'), findsOneWidget);
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
      await tester.tap(find.text('Wer spielt mit?'));
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
