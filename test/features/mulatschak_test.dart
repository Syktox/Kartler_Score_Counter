import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/pump_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Mulatschak mode', () {
    testWidgets('supports multiplier-based scoring and winner display', (
      tester,
    ) async {
      await pumpApp(tester, prefs: mulatschakPrefs());

      expect(find.text('Anna'), findsWidgets);
      expect(find.text('21'), findsNWidgets(2));

      await tester.tap(find.text('+1'));
      await tester.pumpAndSettle();
      expect(find.text('22'), findsOneWidget);

      await tester.tap(find.byKey(const Key('mulatschakMultiplierButton')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('2x'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('+1'));
      await tester.pumpAndSettle();
      expect(find.text('24'), findsOneWidget);
    });

    testWidgets('detects a winner when a player reaches zero', (tester) async {
      await pumpApp(
        tester,
        prefs: mulatschakPrefs(lineup: {'p1': 1, 'p2': 21}),
      );

      expect(find.text('Anna gewinnt!'), findsNothing);

      await tester.tap(find.text('-1'));
      await tester.pumpAndSettle();

      expect(find.text('Anna gewinnt!'), findsOneWidget);
    });

    testWidgets('applies muleqack reset settings to scoring', (tester) async {
      await pumpApp(
        tester,
        prefs: {
          ...mulatschakPrefs(lineup: {'p1': 9, 'p2': 21}),
          'rule_profile': jsonEncode({
            'wattenWinningScore': 11,
            'mulatschakStartingScore': 21,
            'hosnObeStartingLives': 4,
            'muleqackEnabled': true,
            'muleqackTriggerPoints': 10,
            'muleqackResetPoints': 5,
          }),
        },
      );

      await tester.tap(find.text('+5'));
      await tester.pumpAndSettle();

      expect(find.text('9'), findsOneWidget);
    });

    testWidgets('shows history grouped by completed rounds', (tester) async {
      await pumpApp(
        tester,
        prefs: {...mulatschakPrefs(), 'mulatschak_history_enabled': true},
      );

      await tester.tap(find.text('+1'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Ben'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('+1'));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Mulatschak-Verlauf'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Anna'), findsWidgets);
      expect(find.textContaining('Ben'), findsWidgets);
    });

    testWidgets('supports undo of score changes', (tester) async {
      await pumpApp(tester, prefs: mulatschakPrefs());

      await tester.tap(find.text('+1'));
      await tester.pumpAndSettle();
      expect(find.text('22'), findsOneWidget);

      await tester.tap(find.byTooltip('Rückgängig'));
      await tester.pumpAndSettle();
      expect(find.text('21'), findsNWidgets(2));
    });

    testWidgets('persists the multiplier across sessions', (tester) async {
      await pumpApp(tester, prefs: mulatschakPrefs());

      await tester.tap(find.byKey(const Key('mulatschakMultiplierButton')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('4x'));
      await tester.pumpAndSettle();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('mulatschak_multiplier'), 4);
    });
  });
}
