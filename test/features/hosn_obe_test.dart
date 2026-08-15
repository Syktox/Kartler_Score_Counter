import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kartler/app/app.dart';
import 'package:kartler/widgets/score_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/pump_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Hosn Obe mode', () {
    testWidgets('empty lineup offers the lineup picker when players exist', (
      tester,
    ) async {
      await pumpApp(tester, prefs: hosnObePrefs(lineup: {}));

      expect(find.text('Noch keine Spieler'), findsOneWidget);
      expect(find.text('Wer spielt mit?'), findsOneWidget);
      expect(find.text('Spieler verwalten'), findsOneWidget);

      await tester.tap(find.text('Wer spielt mit?'));
      await tester.pumpAndSettle();

      expect(find.text('0 von 2 Spielern spielen mit.'), findsOneWidget);
      expect(find.text('Anna'), findsOneWidget);
      expect(find.text('Ben'), findsOneWidget);
    });

    testWidgets('marks the winner and losers on the player cards', (
      tester,
    ) async {
      await pumpApp(tester, prefs: hosnObePrefs(lineup: {'p1': 1, 'p2': 1}));

      expect(find.text('Ben gewinnt!'), findsNothing);
      expect(find.text('Gewinner'), findsNothing);

      await tester.tap(find.text('-1'));
      await tester.pumpAndSettle();

      expect(find.text('Ben gewinnt!'), findsNothing);
      expect(find.text('Gewinner'), findsOneWidget);
      expect(tester.widget<Text>(find.text('Gewinner')).style?.color, Colors.green);
      expect(find.text('X'), findsOneWidget);
      expect(tester.widget<Text>(find.text('X')).style?.color, Colors.red);
      expect(find.text('Reset'), findsNothing);
    });

    testWidgets('marks players with one life as schwimmt', (tester) async {
      await pumpApp(tester, prefs: hosnObePrefs(lineup: {'p1': 2, 'p2': 1}));

      expect(find.text('Schwimmt'), findsOneWidget);
      expect(tester.widget<Text>(find.text('Schwimmt')).style?.color, Colors.amber);
    });

    testWidgets('uses larger cards so status labels have enough space', (
      tester,
    ) async {
      await pumpApp(tester, prefs: hosnObePrefs());

      final cardSize = tester.getSize(find.widgetWithText(ScoreCard, 'Anna'));
      expect(cardSize.width, 204);
      expect(cardSize.height, greaterThanOrEqualTo(204));
    });

    testWidgets('keeps uppercase names below the status label', (tester) async {
      await pumpApp(
        tester,
        prefs: {
          ...hosnObePrefs(lineup: {'p1': 1, 'p2': 2}),
          'players': jsonEncode([
            {
              'id': 'p1',
              'name': 'MAXIMILIAN',
              'createdAt': '2024-01-01T00:00:00.000Z',
            },
            {
              'id': 'p2',
              'name': 'BEN',
              'createdAt': '2024-01-01T00:00:00.000Z',
            },
          ]),
        },
      );

      expect(
        tester.getBottomLeft(find.text('Schwimmt')).dy,
        lessThan(tester.getTopLeft(find.text('MAXIMILIAN')).dy),
      );
    });

    testWidgets('marks players with no lives left with a red x', (
      tester,
    ) async {
      await pumpApp(tester, prefs: hosnObePrefs(lineup: {'p1': 0, 'p2': 2}));

      expect(find.text('X'), findsOneWidget);
      expect(tester.widget<Text>(find.text('X')).style?.color, Colors.red);
      expect(find.text('Schwimmt'), findsNothing);
    });

    testWidgets('shows three players on one row on handset widths', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(375, 812);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      SharedPreferences.setMockInitialValues({
        ...hosnObePrefs(lineup: {'p1': 4, 'p2': 4, 'p3': 4}),
        'players': jsonEncode([
          {'id': 'p1', 'name': 'Max', 'createdAt': '2024-01-01T00:00:00.000Z'},
          {'id': 'p2', 'name': 'Ben', 'createdAt': '2024-01-01T00:00:00.000Z'},
          {'id': 'p3', 'name': 'Tim', 'createdAt': '2024-01-01T00:00:00.000Z'},
        ]),
      });
      await tester.pumpWidget(const KartlerApp());
      await tester.pumpAndSettle();
      await dismissStartScreen(tester);

      final maxCard = tester.getRect(find.widgetWithText(ScoreCard, 'Max'));
      final benCard = tester.getRect(find.widgetWithText(ScoreCard, 'Ben'));
      final timCard = tester.getRect(find.widgetWithText(ScoreCard, 'Tim'));

      expect(maxCard.top, benCard.top);
      expect(benCard.top, timCard.top);
      expect(maxCard.size, benCard.size);
      expect(benCard.size, timCard.size);
      expect(maxCard.left, lessThan(benCard.left));
      expect(benCard.left, lessThan(timCard.left));
      expect(tester.takeException(), isNull);
    });

    testWidgets('supports undo after losing a life', (tester) async {
      await pumpApp(tester, prefs: hosnObePrefs());

      await tester.tap(find.text('-1'));
      await tester.pumpAndSettle();
      expect(find.text('3'), findsOneWidget);

      await tester.tap(find.byTooltip('Rückgängig'));
      await tester.pumpAndSettle();
      expect(find.text('4'), findsNWidgets(2));
    });

    testWidgets('keeps the selected player highlighted', (tester) async {
      await pumpApp(tester, prefs: hosnObePrefs());

      await tester.tap(find.text('Ben'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('-1'));
      await tester.pumpAndSettle();

      expect(find.text('3'), findsOneWidget);
      expect(find.text('Ben'), findsWidgets);
    });
  });
}
