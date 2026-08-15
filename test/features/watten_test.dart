import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kartler/main.dart';
import 'package:kartler/widgets/score_card.dart';
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

      expect(find.text('Ich gewinnt!'), findsNothing);
      expect(find.text('Gewinner'), findsNothing);

      await tester.tap(find.text('+2'));
      await tester.pumpAndSettle();

      expect(find.text('12'), findsOneWidget);
      expect(find.text('Ich gewinnt!'), findsNothing);
      expect(find.text('Gewinner'), findsOneWidget);
      expect(find.text('X'), findsOneWidget);

      await tester.tap(find.text('Streichen'));
      await tester.pumpAndSettle();

      expect(find.text('0'), findsOneWidget);
      expect(find.text('Gewinner'), findsNothing);
      expect(find.text('X'), findsNothing);
    });

    testWidgets('does not show a game title anymore', (tester) async {
      await pumpApp(tester, prefs: wattenPrefs());

      expect(find.text('Spiel 1'), findsNothing);
    });

    testWidgets('keeps portrait score cards at their compact original height', (
      tester,
    ) async {
      await pumpApp(tester, prefs: wattenPrefs());

      final cardSize = tester.getSize(find.widgetWithText(ScoreCard, 'Ich'));
      expect(cardSize.width, greaterThan(650));
      expect(
        cardSize.height,
        lessThanOrEqualTo(270),
      );
    });

    testWidgets('records Watten history while its presentation is hidden', (
      tester,
    ) async {
      await pumpApp(tester, prefs: wattenPrefs());

      await tester.tap(find.text('+2'));
      await tester.pumpAndSettle();

      expect(find.byTooltip('Watten-Verlauf'), findsNothing);
      final prefs = await SharedPreferences.getInstance();
      final history = jsonDecode(prefs.getString('watten_history')!) as List;
      expect(history, hasLength(1));
      expect(history.single, contains('"points":2'));
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
      expect(matches.single['standings'], {'Ich': 10, 'Du': 3});

      expect(find.text('0'), findsNWidgets(2));
      expect(find.text('Ich gewinnt!'), findsNothing);
      expect(find.text('Gewinner'), findsNothing);
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
      expect(matches.single['winnerLabel'], 'Ich');
    });

    testWidgets('new game clears the score history', (tester) async {
      await pumpApp(
        tester,
        prefs: {...wattenPrefs(), 'watten_history_enabled': true},
      );

      await tester.tap(find.text('+2'));
      await tester.pumpAndSettle();

      await openDrawer(tester);
      await tester.tap(find.text('Neues Spiel'));
      await tester.pumpAndSettle();

      final prefs = await SharedPreferences.getInstance();
      expect(jsonDecode(prefs.getString('watten_history')!), isEmpty);
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

      expect(find.text('Ich gewinnt!'), findsNothing);
      expect(find.text('Gewinner'), findsNothing);

      await tester.tap(find.text('+2'));
      await tester.pumpAndSettle();

      expect(find.text('16'), findsOneWidget);
      expect(find.text('Ich gewinnt!'), findsNothing);
      expect(find.text('Gewinner'), findsOneWidget);
      expect(find.text('X'), findsOneWidget);
    });

    testWidgets('marks teams as gespannt shortly before the configured win', (
      tester,
    ) async {
      await pumpApp(
        tester,
        prefs: {
          ...wattenPrefs(),
          'watten_lineup': jsonEncode({
            'Spiel 1': {'me': 13, 'you': 12},
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

      expect(find.text('Gespannt'), findsOneWidget);
      expect(tester.widget<Text>(find.text('Gespannt')).style?.color, Colors.amber);
      expect(find.text('Streichen'), findsOneWidget);
      expect(find.text('Reset'), findsNothing);
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

      SharedPreferences.setMockInitialValues({...wattenPrefs()});
      await tester.pumpWidget(const KartlerApp());
      await tester.pumpAndSettle();
      await dismissStartScreen(tester);

      await tester.tap(find.byTooltip('Tischmodus').first);
      await tester.pumpAndSettle();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('watten_table_mode'), isTrue);
    });

    for (final platform in const [
      TargetPlatform.macOS,
      TargetPlatform.windows,
      TargetPlatform.linux,
    ]) {
      testWidgets('hides table mode on ${platform.name} desktop', (
        tester,
      ) async {
        debugDefaultTargetPlatformOverride = platform;
        try {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = const Size(1200, 800);
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          SharedPreferences.setMockInitialValues({...wattenPrefs()});
          await tester.pumpWidget(const KartlerApp());
          await tester.pumpAndSettle();
          await dismissStartScreen(tester);

          expect(find.byTooltip('Tischmodus'), findsNothing);
          expect(tester.takeException(), isNull);
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      });
    }
  });
}
