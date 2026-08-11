import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/pump_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Watten mode', () {
    testWidgets('supports score updates, winner display and side reset', (
      tester,
    ) async {
      await pumpApp(
        tester,
        prefs: {
          ...wattenPrefs(),
          'watten_lineup': jsonEncode({
            'Spiel 1': {'me': 10, 'you': 3},
          }),
        },
      );

      expect(find.text('Wir gewinnt!'), findsNothing);

      await tester.tap(find.text('+2'));
      await tester.pumpAndSettle();

      expect(find.text('12'), findsOneWidget);
      expect(find.text('Wir gewinnt!'), findsOneWidget);

      await tester.tap(find.text('Reset'));
      await tester.pumpAndSettle();

      expect(find.text('0'), findsOneWidget);
      expect(find.text('Wir gewinnt!'), findsNothing);
    });

    testWidgets('supports adding, renaming and deleting games', (tester) async {
      await pumpApp(tester, prefs: wattenPrefs());

      await openDrawer(tester);
      await tester.tap(find.text('Neues Spiel'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Best of 3');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(find.text('Best of 3'), findsOneWidget);

      await openDrawer(tester);
      await tester.tap(drawerActionForItem('Best of 3', 'Umbenennen'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Finale');
      await tester.tap(find.widgetWithText(TextButton, 'Umbenennen'));
      await tester.pumpAndSettle();

      expect(find.text('Finale'), findsWidgets);

      await openDrawer(tester);
      await tester.tap(drawerActionForItem('Finale', 'Löschen'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Löschen'));
      await tester.pumpAndSettle();
      await closeDrawer(tester);

      expect(find.text('Spiel 1'), findsOneWidget);
      expect(find.text('Finale'), findsNothing);
    });

    testWidgets('respects a custom winning score from the rule profile', (
      tester,
    ) async {
      await pumpApp(
        tester,
        prefs: {
          ...wattenPrefs(),
          'watten_lineup': jsonEncode({
            'Spiel 1': {'me': 14, 'you': 10},
          }),
          'rule_profile': jsonEncode({
            'wattenWinningScore': 15,
            'mulatschakStartingScore': 21,
            'hosnObeStartingLives': 4,
            'muleqackEnabled': false,
            'muleqackTriggerPoints': 100,
            'muleqackResetPoints': 50,
          }),
        },
      );

      expect(find.text('Wir gewinnt!'), findsNothing);

      await tester.tap(find.text('+2'));
      await tester.pumpAndSettle();

      expect(find.text('16'), findsOneWidget);
      expect(find.text('Wir gewinnt!'), findsOneWidget);
    });

    testWidgets('toggles table mode from the app bar', (tester) async {
      await pumpApp(tester, prefs: wattenPrefs());

      await tester.tap(find.byTooltip('Tischmodus'));
      await tester.pumpAndSettle();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('watten_table_mode'), isTrue);
    });
  });
}
