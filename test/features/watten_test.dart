import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kartler/main.dart';
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

    testWidgets('does not show a game title anymore', (tester) async {
      await pumpApp(tester, prefs: wattenPrefs());

      expect(find.text('Spiel 1'), findsNothing);
    });

    testWidgets('new game records the finished game and starts a fresh one', (
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

      await openDrawer(tester);
      await tester.tap(find.text('Neues Spiel'));
      await tester.pumpAndSettle();

      final prefs = await SharedPreferences.getInstance();
      final matches = jsonDecode(prefs.getString('match_history')!) as List;
      expect(matches, hasLength(1));
      expect(matches.single['gameType'], 'watten');
      expect(matches.single['winnerLabel'], isNull);
      expect(matches.single['standings'], {'Wir': 10, 'Die': 3});

      expect(find.text('0'), findsNWidgets(2));
      expect(find.text('Wir gewinnt!'), findsNothing);
      expect(find.text('Partie aufgezeichnet!'), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('records the winner when the game is finished', (tester) async {
      await pumpApp(
        tester,
        prefs: {
          ...wattenPrefs(),
          'watten_lineup': jsonEncode({
            'Spiel 1': {'me': 11, 'you': 6},
          }),
        },
      );

      await openDrawer(tester);
      await tester.tap(find.text('Neues Spiel'));
      await tester.pumpAndSettle();

      final prefs = await SharedPreferences.getInstance();
      final matches = jsonDecode(prefs.getString('match_history')!) as List;
      expect(matches, hasLength(1));
      expect(matches.single['winnerLabel'], 'Wir');
    });

    testWidgets('new game on an empty board does not record anything', (
      tester,
    ) async {
      await pumpApp(tester, prefs: wattenPrefs());

      await openDrawer(tester);
      await tester.tap(find.text('Neues Spiel'));
      await tester.pumpAndSettle();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('match_history'), isNull);
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

    testWidgets('hides the table mode toggle in the portrait app bar', (
      tester,
    ) async {
      await pumpApp(tester, prefs: wattenPrefs());

      expect(find.byTooltip('Tischmodus'), findsNothing);
    });

    testWidgets('toggles table mode from the landscape app bar', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(800, 360);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      SharedPreferences.setMockInitialValues({
        ...wattenPrefs(),
      });
      await tester.pumpWidget(const KartlerApp());
      await tester.pumpAndSettle();
      await dismissOnboarding(tester);

      await tester.tap(find.byTooltip('Tischmodus').first);
      await tester.pumpAndSettle();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('watten_table_mode'), isTrue);
    });
  });
}
