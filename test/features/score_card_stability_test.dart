import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kartler/app/app.dart';
import 'package:kartler/widgets/score_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/pump_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpAtPhoneSize(
    WidgetTester tester,
    Map<String, Object> prefs, {
    Size size = const Size(375, 812),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SharedPreferences.setMockInitialValues(prefs);
    await tester.pumpWidget(const KartlerApp());
    await tester.pumpAndSettle();
    await dismissStartScreen(tester);
  }

  Map<String, Object> mixedNames() {
    return {
      'players': jsonEncode([
        {'id': 'p1', 'name': 'Ichwilldasnicht', 'createdAt': '2024-01-01T00:00:00.000Z'},
        {'id': 'p2', 'name': 'Schnapskartl Maria Theresia', 'createdAt': '2024-01-01T00:00:00.000Z'},
      ]),
    };
  }

  Future<void> expectSameScoreTop(WidgetTester tester) async {
    final firstCard = find.widgetWithText(ScoreCard, 'Ichwilldasnicht');
    final secondCard = find.widgetWithText(
      ScoreCard,
      'Schnapskartl Maria Theresia',
    );
    final firstScore = tester.getRect(
      find.descendant(of: firstCard, matching: find.text('21')),
    );
    final secondScore = tester.getRect(
      find.descendant(of: secondCard, matching: find.text('21')),
    );
    expect(
      secondScore.top,
      firstScore.top,
      reason: 'the score must sit at the same spot on every card',
    );
    expect(secondScore.bottom, firstScore.bottom);
    expect(tester.takeException(), isNull);
  }

  Map<String, Object> longNames() {
    return {
      'players': jsonEncode([
        {'id': 'p1', 'name': 'Anna', 'createdAt': '2024-01-01T00:00:00.000Z'},
        {'id': 'p2', 'name': 'Was Geht', 'createdAt': '2024-01-01T00:00:00.000Z'},
        {'id': 'p3', 'name': 'Tim', 'createdAt': '2024-01-01T00:00:00.000Z'},
      ]),
    };
  }

  testWidgets('mulatschak: name stays put when the card is clicked', (
    tester,
  ) async {
    await pumpAtPhoneSize(
      tester,
      {...mulatschakPrefs(lineup: {'p1': 21, 'p2': 21, 'p3': 21}), ...longNames()},
    );

final nameBefore = tester.getRect(find.text('Was Geht'));
    final cardBefore = tester.getRect(find.byType(ScoreCard).at(1));
    final gridBefore = tester.getRect(find.byType(GridView));

    await tester.tap(find.text('Was Geht'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 300));

    expect(tester.getRect(find.text('Was Geht')), nameBefore);
    expect(tester.getRect(find.byType(ScoreCard).at(1)), cardBefore);
    expect(tester.getRect(find.byType(GridView)), gridBefore);
    expect(tester.takeException(), isNull);
  });

  testWidgets('mulatschak: two-line names do not move the score of a card', (
    tester,
  ) async {
    await pumpAtPhoneSize(
      tester,
      {
        ...mulatschakPrefs(lineup: {'p1': 21, 'p2': 21, 'p3': 21}),
        'players': jsonEncode([
          {
            'id': 'p1',
            'name': 'Anna',
            'createdAt': '2024-01-01T00:00:00.000Z',
          },
          {
            'id': 'p2',
            'name': 'Schnapskartl Maria Theresia',
            'createdAt': '2024-01-01T00:00:00.000Z',
          },
          {
            'id': 'p3',
            'name': 'Tim',
            'createdAt': '2024-01-01T00:00:00.000Z',
          },
        ]),
      },
    );

    final shortNameCard = find.widgetWithText(ScoreCard, 'Anna');
    final longNameCard = find.widgetWithText(
      ScoreCard,
      'Schnapskartl Maria Theresia',
    );

    final shortNameScore = tester.getRect(
      find.descendant(of: shortNameCard, matching: find.text('21')),
    );
    final longNameScore = tester.getRect(
      find.descendant(of: longNameCard, matching: find.text('21')),
    );
    expect(
      longNameScore.top,
      shortNameScore.top,
      reason: 'the score must sit at the same spot on every card',
    );
    expect(longNameScore.bottom, shortNameScore.bottom);
    expect(tester.takeException(), isNull);
  });

  testWidgets('scores of IchKanndasallesnichtmehr and Markus lie on the same line', (
    tester,
  ) async {
    await pumpAtPhoneSize(
      tester,
      {
        ...mulatschakPrefs(lineup: {'p1': 21, 'p2': 21}),
        'players': jsonEncode([
          {
            'id': 'p1',
            'name': 'IchKanndasallesnichtmehr',
            'createdAt': '2024-01-01T00:00:00.000Z',
          },
          {
            'id': 'p2',
            'name': 'Markus',
            'createdAt': '2024-01-01T00:00:00.000Z',
          },
        ]),
      },
    );

    final ichCard = find.widgetWithText(ScoreCard, 'IchKanndasallesnichtmehr');
    final markusCard = find.widgetWithText(ScoreCard, 'Markus');
    final ichScore = tester.getRect(
      find.descendant(of: ichCard, matching: find.text('21')),
    );
    final markusScore = tester.getRect(
      find.descendant(of: markusCard, matching: find.text('21')),
    );
    expect(
      tester.getRect(ichCard).center.dy == tester.getRect(markusCard).center.dy,
      isTrue,
      reason: 'the two cards must sit next to each other in one row',
    );
    expect(
      markusScore.top,
      ichScore.top,
      reason: 'the two scores must lie on the same horizontal line',
    );
    expect(markusScore.bottom, ichScore.bottom);
    expect(tester.takeException(), isNull);
  });

  testWidgets('mulatschak wrap: scores align on one line for one- and two-line names', (
    tester,
  ) async {
    await pumpAtPhoneSize(
      tester,
      {
        ...mulatschakPrefs(lineup: {'p1': 21, 'p2': 21}),
        ...mixedNames(),
      },
      size: const Size(700, 812),
    );

    final firstCard = find.widgetWithText(ScoreCard, 'Ichwilldasnicht');
    final secondCard = find.widgetWithText(
      ScoreCard,
      'Schnapskartl Maria Theresia',
    );
    expect(
      tester.getRect(firstCard).center.dy == tester.getRect(secondCard).center.dy,
      isTrue,
      reason: 'the two cards must sit next to each other in one row',
    );

    await expectSameScoreTop(tester);
  });

  testWidgets('mulatschak compact landscape: scores align on one line', (
    tester,
  ) async {
    await pumpAtPhoneSize(
      tester,
      {
        ...mulatschakPrefs(lineup: {'p1': 21, 'p2': 21}),
        ...mixedNames(),
      },
      size: const Size(812, 375),
    );

    await expectSameScoreTop(tester);
  });

  testWidgets('hosn obe: scores align on one line for one- and two-line names', (
    tester,
  ) async {
    await pumpAtPhoneSize(
      tester,
      {
        ...hosnObePrefs(lineup: {'p1': 21, 'p2': 21}),
        ...mixedNames(),
      },
    );

    await expectSameScoreTop(tester);
  });

  testWidgets('mulatschak: score text stays at the same spot when the score changes', (
    tester,
  ) async {
    await pumpAtPhoneSize(
      tester,
      {...mulatschakPrefs(lineup: {'p1': 21, 'p2': 21, 'p3': 21}), ...longNames()},
    );

    await tester.tap(find.text('Was Geht'));
    await tester.pumpAndSettle();

    final card = find.widgetWithText(ScoreCard, 'Was Geht');
    final scoreBefore = tester.getRect(
      find.descendant(of: card, matching: find.text('21')),
    );

    await tester.tap(find.text('+1'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      tester.getRect(
        find.descendant(of: card, matching: find.text('22')),
      ),
      scoreBefore,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('hosn obe: name stays put when the card is clicked', (
    tester,
  ) async {
    await pumpAtPhoneSize(
      tester,
      {...hosnObePrefs(lineup: {'p1': 4, 'p2': 4, 'p3': 4}), ...longNames()},
    );

    final nameBefore = tester.getRect(find.text('Was Geht'));
    final cardBefore = tester.getRect(
      find.widgetWithText(ScoreCard, 'Was Geht'),
    );

    await tester.tap(find.text('Was Geht'));
    await tester.pumpAndSettle();

    expect(tester.getRect(find.text('Was Geht')), nameBefore);
    expect(
      tester.getRect(find.widgetWithText(ScoreCard, 'Was Geht')),
      cardBefore,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('hosn obe: score text stays at the same spot when the score changes', (
    tester,
  ) async {
    await pumpAtPhoneSize(
      tester,
      {...hosnObePrefs(lineup: {'p1': 4, 'p2': 4, 'p3': 4}), ...longNames()},
    );

    await tester.tap(find.text('Was Geht'));
    await tester.pumpAndSettle();

    final card = find.widgetWithText(ScoreCard, 'Was Geht');
    final scoreBefore = tester.getRect(
      find.descendant(of: card, matching: find.text('4')),
    );

    await tester.tap(find.text('-1'));
    await tester.pumpAndSettle();

    expect(
      tester.getRect(
        find.descendant(of: card, matching: find.text('3')),
      ),
      scoreBefore,
    );
    expect(tester.takeException(), isNull);
  });
}