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
    Map<String, Object> prefs,
  ) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SharedPreferences.setMockInitialValues(prefs);
    await tester.pumpWidget(const KartlerApp());
    await tester.pumpAndSettle();
    await dismissStartScreen(tester);
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
}